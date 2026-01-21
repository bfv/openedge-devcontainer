 
/*------------------------------------------------------------------------
   File        : WebHandlerExt
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : bronco
   Created     : Wed May 17 15:32:46 CEST 2017
   Notes       : 
 ----------------------------------------------------------------------*/


block-level on error undo, throw.

using OpenEdge.Core.Collections.StringStringMap.
using OpenEdge.Core.String.
using OpenEdge.Net.HTTP.Cookie.
using OpenEdge.Net.HTTP.HttpHeader.
using OpenEdge.Net.HTTP.IHttpResponse.
using OpenEdge.Web.IWebRequest.
using OpenEdge.Web.WebHandler.
using OpenEdge.Web.WebResponse.
using OpenEdge.Web.WebResponseWriter.
using Progress.Json.ObjectModel.JsonArray.
using Progress.Json.ObjectModel.JsonObject.
using Progress.Lang.OERequestInfo.
using Progress.Lang.AppError.
using OpenEdge.Core.Memptr.

class WebHandlerExt inherits WebHandler: 
  
  define private property queryParameters as StringStringMap no-undo get. set.
  define private static property callCount as integer no-undo get. set.
  
  constructor public WebHandlerExt():
    
  end.
		
  method override protected integer HandleGet(request as IWebRequest):
    
    define variable response as IHttpResponse no-undo.
    define variable writer as OpenEdge.Web.WebResponseWriter  no-undo.               
    define variable endpoint as character no-undo.
    define variable errorFound as logical no-undo.
    
    this-object:extractHttpInfo(request).
    
    endpoint = request:GetContextValue('URI_FINAL_MATCH_GROUP').
    message substitute('GET: &1', endpoint).
    
    callCount = callCount + 1.
    
    errorFound = false.
    case endpoint:
      
      when '/' then 
        response = this-object:processHome(request).
        
      when '/get' then
        response = this-object:processGet(request).
      
      when '/cookie' then
        response = this-object:processCookie(request, false).
      
      when '/persistentcookie' then
        response = this-object:processCookie(request, true).
      
      when '/customers' then
        response = this-object:processCustomer(request, false).
             
      when '/customerscache' then
        response = this-object:processCustomer(request, true).
      
      when '/propath' then
        response = this-object:processPropath(request).
      
      // entries to fiddle with auth
      when '/admin' or when '/system' or when '/info' then
        response = this-object:processSandboxCalls(request).
         
      when '' then 
        response = this-object:processHealth(request).
            
      otherwise do:
        response = this-object:processNotAllowed(request).  
        errorFound = true.
      end.
        
    end case.
      
    writer = new WebResponseWriter(response).
    writer:Open().
    writer:Close().
        
    return 0.
    
  end method.  // HandleGet
  
  
  method override protected integer HandlePost(request as IWebRequest):
    
    define variable response as IHttpResponse no-undo.
    define variable writer as OpenEdge.Web.WebResponseWriter  no-undo.               
    define variable endpoint as character no-undo.
    
    endpoint = request:GetContextValue('URI_FINAL_MATCH_GROUP').
    
    case endpoint:
      
      when '/' then 
        response = this-object:processHome(request).
        
      when '/post' then
        response = this-object:processGet(request).  // W.I.P.
        
      when "/memleak" then
        response = this-object:processMemleak(request).
      
      otherwise do:
        response = this-object:processNotAllowed(request).  
      end.
        
    end case.
         
    writer = new WebResponseWriter(response).
    writer:Open().
    writer:Close().
        
    return 0.
    
  end method.  // HandlePost

  
  method override protected integer HandleNotAllowedMethod( webRequest as OpenEdge.Web.IWebRequest ):
    undo, throw new Progress.Lang.AppError('METHOD NOT IMPLEMENTED').
  end method.


  method override protected integer HandleNotImplemented(webRequest as OpenEdge.Web.IWebRequest ):
    undo, throw new Progress.Lang.AppError('METHOD NOT IMPLEMENTED').
  end method.
  
  
  method private WebHandlerExt addHeaders(request as IWebRequest, json as JsonObject):
    
    define variable headerJson as JsonObject no-undo.
    define variable headers as HttpHeader extent no-undo.
    define variable currentHeader as HttpHeader no-undo.
    define variable headerCount as integer no-undo.
    define variable i as integer no-undo.
    
    headerJson = new JsonObject().
    
    headerCount = request:GetHeaders(headers).
    do i = 1 to headerCount:
      currentHeader = headers[i].
      headerJson:Add(this-object:normalizeHeaderName(currentHeader:Name), currentHeader:Value).
    end.
    
    json:Add('headers', headerJson).
    
    return this-object.
    
  end method.  // addHeaders 
  
  
  method private WebHandlerExt addQueryParameters(request as IWebRequest, json as JsonObject):
    
    define variable parameterJson as JsonObject no-undo.
    define variable parameterCount as integer no-undo.
    define variable i as integer no-undo.
    define variable parameters as character no-undo.
    define variable currentEntry as character no-undo.
    define variable parameterName as character no-undo.
    define variable parameterValue as character no-undo.
    
    parameterJson = new JsonObject().
    parameters = request:GetContextValue('QUERY_STRING').
    
    parameterCount = num-entries(parameters, '&').
    do i = 1 to parameterCount:
      currentEntry = entry(i, parameters, '&').
      parameterName = entry(1, currentEntry, '=').
      parameterValue = this-object:urlDecode(entry(2, currentEntry, '=')).
      parameterJson:Add(parameterName, parameterValue).
    end.
            
    json:Add('args', parameterJson).
    
    return this-object.
    
  end method.  // addQueryParameters
  

  method private WebHandlerExt addInstanceInfo(request as IWebRequest, json as JsonObject):
    
    define variable instanceJson as JsonObject no-undo.
    define variable environment as character no-undo.
    define variable instanceId as character no-undo.
    
    environment = os-getenv('OE_ENVIRONMENT').
    if (environment = ?) then
        environment = '<unknown>'.
    
    instanceId = os-getenv('INSTANCE_ID').
    if (instanceId = ?) then 
      instanceId = 'default'.
      
    instanceJson = new JsonObject().
    instanceJson:Add('environment', environment).
    instanceJson:Add('id', instanceId).
    instanceJson:Add('calls', callCount).
        
    json:Add('instance', instanceJson).
    
    return this-object.
    
  end method.  // addInstanceInfo
  
    
  method private WebHandlerExt addPathParameters(request as IWebRequest, json as JsonObject):
    
    define variable parameterJson as JsonObject no-undo.
    define variable parameterCount as integer no-undo.
    define variable i as integer no-undo.
    define variable parameters as character no-undo.
    define variable parameterName as character no-undo.
    define variable parameterValue as character no-undo.
    
    parameterJson = new JsonObject().
    parameters = request:PathParameterNames.
    
    parameterCount = num-entries(parameters).
    do i = 1 to parameterCount:
      parameterName = entry(i, parameters).
      parameterValue = request:GetPathParameter(parameterName).
      parameterJson:Add(parameterName, parameterValue).
    end.
            
    json:Add('pathparameters', parameterJson).
    
    return this-object.
    
  end method.  // addPathParameters


  method private WebHandlerExt addContext(request as IWebRequest, json as JsonObject):
    
    define variable parameterJson as JsonObject no-undo.
    define variable parameterCount as integer no-undo.
    define variable i as integer no-undo.
    define variable parameters as character no-undo.
    define variable parameterName as character no-undo.
    define variable parameterValue as character no-undo.
    
    parameterJson = new JsonObject().
    parameters = request:ContextNames.
    
    parameterCount = num-entries(parameters).
    do i = 1 to parameterCount:
      parameterName = entry(i, parameters).
      parameterValue = request:GetContextValue(parameterName).
      parameterJson:Add(parameterName, parameterValue).
    end.
            
    json:Add('context', parameterJson).
    
    return this-object.
    
  end method.  // addContext

  
  method private WebHandlerExt addOpenEdgeInformation(request as IWebRequest, json as JsonObject):
    
    this-object
      :addContext(request, json)
      :addPathParameters(request, json)
      :addPropath(request, json)
      :addVersion(request, json)
      :addDotnetVersion(json)
      :addCurrentRequestInfo(request, json)
      .

    return this-object.
    
  end method.  // addOpenEdgeInformation
  
  
  method private WebHandlerExt addDotnetVersion(json as JsonObject):

    var char dotnet = System.Environment:Version:ToString().
    json:Add("dotnet", dotnet).

    return this-object.

  end method. 


  method private WebHandlerExt addStandardHttp(request as IWebRequest, json as JsonObject):
    
    define variable local as JsonObject no-undo.
    
    json:Add('origin', request:RemoteHost).        
    json:Add('url', request:URI:BaseURI + request:URI:Path).  
    
    local = new JsonObject().
    local:Add('ip', request:GetContextValue('LOCAL_ADDR')).
    
    json:Add('local', local).
    
    return this-object.

  end method.  // addStandardHttp
  
  
  method private IHttpResponse processCookie(request as IWebRequest, persistentCookie as logical):
    
    define variable response as IHttpResponse no-undo.
    define variable cookie as Cookie no-undo.
    define variable path as character no-undo.
    define variable maxAge as integer no-undo.
    define variable urlMaxage as character no-undo.
    define variable host as character no-undo.
    
    response = new WebResponse().
    response:ContentType = 'text/plain'.
    response:Entity = new String('you got a cookie').
    
    path = request:GetContextValue('SERVLET_APPLICATION_URL') + request:GetContextValue('URI_FINAL_MATCH_GROUP').   
    host = request:GetHeader("Host"):GetParameterValue ("Host").
         
    if (persistentCookie) then do:
      maxAge = 600.
      urlMaxage = this-object:queryParameters:Get('maxage').
      if (urlMaxage > '') then
        maxAge = integer(urlMaxage) no-error.
        
      cookie = new Cookie('test', host, path, 'succeeded', maxAge, ?, false, true, ?).
      
    end.
    else 
      cookie = new Cookie('test', host, path, 'succeeded').
    
    response:SetCookie(cookie).
      
    return response.
    
  end method.  // processCookie
  
  
  method private IHttpResponse processCustomer(request as IWebRequest, cached as logical):
    
    define variable response as IHttpResponse no-undo.
    define variable json as JsonArray no-undo.
    define variable cacheHeader as HttpHeader no-undo.
    
    response = new WebResponse().
    
    if (not connected('sports2000') and not connected('sports2020')) then do:
      response:ContentType = 'text/plain'.
      response:Entity = new String('sports2000/2020 not connected').
    end.
    else do:
      json = this-object:customersToJson(request).
      response:ContentType = 'application/json'.
      response:Entity = json.
      if (cached) then do:
        cacheHeader = new HttpHeader('Cache-Control', 'max-age=60').
        response:SetHeader(cacheHeader).
      end.   
    end.
    
    return response.
    
  end method.  // processCustomer
  
  
  method private IHttpResponse processGet(request as IWebRequest):
    
    define variable response as IHttpResponse no-undo.
    define variable json as JsonObject no-undo.
    define variable oeJson as JsonObject no-undo.
        
    response = new WebResponse().
    response:ContentType = 'application/json'.
    
    json = new JsonObject().
    this-object
        :addQueryParameters(request, json)
        :addInstanceInfo(request, json)
        :addStandardHttp(request, json)
        :addHeaders(request, json)
        .
    
    oeJson = new JsonObject().
    
    if (this-object:queryParameters:Get('openedge') = 'true') then do:
      this-object:addOpenEdgeInformation(request, oeJson).
      json:Add('openedge', oeJson).
    end.

    response:Entity = json.
    
    return response.
    
  end method.  // processGet


  method private IHttpResponse processPropath(request as IWebRequest):
    
    define variable response as IHttpResponse no-undo.
    define variable json as JsonObject no-undo.
    
    response = new WebResponse().
    response:ContentType = 'application/json'.
    
    json = new JsonObject().
    json:Add('propath', this-object:getPropathJson()).
     
    response:Entity = json.
    
    return response.
    
  end method.  // processPropath


  method private JsonArray getPropathJson():
    
    define variable jsonArray as JsonArray no-undo.
    define variable i as integer no-undo.
    define variable numEntries as integer no-undo.
    
    jsonArray = new JsonArray().
    
    numEntries = num-entries(propath).
    do i = 1 to numEntries:
      jsonArray:Add(entry(i, propath)).
    end.
    
    return jsonArray.
    
  end method.  // getPropathJson
  
  
  method private WebHandlerExt addPropath(request as IWebRequest, json as JsonObject):
    
    json:Add('propath', this-object:getPropathJson()).
    
    return this-object.
    
  end method.  // addPropath
    
  
  method private WebHandlerExt addVersion(request as IWebRequest, json as JsonObject):
    
    json:Add('version', proversion()).
    
    return this-object.
    
  end method.  // addVersion
  

  method private WebHandlerExt addCurrentRequestInfo(request as IWebRequest, json as JsonObject):
    
    define variable currentRequestInfo as OERequestInfo no-undo.
    define variable jsonRequestInfo as JsonObject no-undo.
    define variable jsonCP as JsonObject no-undo.
    
    
    currentRequestInfo = session:current-request-info.

    jsonRequestInfo = new JsonObject().
    jsonRequestInfo:Add('agentId', currentRequestInfo:AgentId).
    jsonRequestInfo:Add('clientContextId', currentRequestInfo:ClientContextId).
    jsonRequestInfo:Add('procedureName', currentRequestInfo:ProcedureName).
    jsonRequestInfo:Add('requestId', currentRequestInfo:RequestId).
    jsonRequestInfo:Add('sessionId', currentRequestInfo:SessionId).
    jsonRequestInfo:Add('threadId', currentRequestInfo:ThreadId).
    
    jsonCP = this-object:getCPInfo(currentRequestInfo).
    jsonRequestInfo:Add("clientPrincipal", jsonCP).
    
    json:Add('currentRequestInfo', jsonRequestInfo).
    
    return this-object.
    
  end method.  // addCurrentRequestInfo
  
  
  method private JsonObject getCPInfo(currentRequestInfo as OERequestInfo):
    
    define variable jsonCP as JsonObject no-undo.
    define variable hCP as handle no-undo.
    define variable propList as character no-undo.
    define variable propCount as integer no-undo.
    define variable propName as character no-undo.
    define variable propValue as character no-undo.
    define variable i as integer no-undo.
    
    jsonCP = new JsonObject().

    hCP = currentRequestInfo:GetClientPrincipal().    
    if (valid-handle(hCP)) then do:
      
      jsonCP:Add('userid', hCP:user-id).
      
      propList = hCP:list-property-names().
      propCount = num-entries(propList).
      
      do i = 1 to propCount:
        propName = entry(i, propList).
        propValue = hCP:get-property(propName).
        jsonCP:Add(propName, propValue).
      end.
      
    end.  // if (valid-handle(hCP))...
        
    return jsonCP.
    
  end method.  // getCPInfo
  
  
  method private IHttpResponse processHealth(request as IWebRequest):
      
    define variable response as IHttpResponse no-undo.
     
    // for demo purposes we return 'unhealthy' after 10 calls
    response = new WebResponse().
    response:StatusCode = (if (callCount <= 10) then 200 else 500).
    response:Entity = new String('').
    response:ContentType = 'text/plain'.
    
    return response.
       
  end method.  // processHealth
  
  
  method private IHttpResponse processHome(request as IWebRequest):
    
    define variable response as IHttpResponse no-undo.
    define variable htmlContent as longchar no-undo.
    define variable htmlFile as character no-undo.
    
    htmlFile = search('home.html').
    copy-lob file htmlFile to htmlContent.
    
    response = new WebResponse().
    response:Entity = new String(htmlContent).
    response:ContentType = 'text/html'.    
    
    return response.

  end method.  // processHome
  
  
  method private IHttpResponse processSandboxCalls(request as IWebRequest):

    define variable response as IHttpResponse no-undo.
    define variable json as JsonObject no-undo.
    
    json = new JsonObject().
    json:Add('get', string(request:GetContextValue('PATH_INFO'))).
    
    response = new WebResponse().
    response:Entity = json.
    response:ContentType = 'application/json'.    
    
    return response.
    
  end method.  // processSanboxCalls
  
    
  method private IHttpResponse processNotAllowed(request as IWebRequest):
    
    define variable response as IHttpResponse no-undo.
    
    response = new WebResponse().
    
    response:StatusCode = 405.
    response:StatusReason = 'Method Not Allowed'.
    response:ContentType = 'text/html'.
    response:Entity = new String(
      '405: ' + request:Method + ' of ' + quoter(request:GetContextValue('URI_FINAL_MATCH_GROUP')) + ' not allowed'
    ).
    
    return response.
    
  end method.  // processNotAllowed
  
  
  method private IHttpResponse processMemleak(request as IWebRequest):
    
    define variable response as IHttpResponse no-undo.
    define variable json as JsonObject no-undo.
    define variable body as OpenEdge.Core.Memptr no-undo.
    define variable str as character no-undo.
    define variable leakBytes as int64 no-undo.
    define variable memleak as memptr no-undo.
    
    body = cast(request:Entity, OpenEdge.Core.Memptr).
    str = string(body:GetString(1)).
    if (str > "") then do:
      leakBytes = stringToNumber(replace(str, "bytes=", "")).
      set-size(memleak) = leakBytes.
    end.

    json = new JsonObject().
    json:Add('leaked', leakBytes).
    
    
    response = new WebResponse().
    
    response:StatusCode = 200.
    response:StatusReason = 'OK'.
    response:ContentType = 'application/json'.

    response:Entity = json.
    
    return response.
    
  end method.  // processMemleak
  
  
  method private character urlDecode(urlEntry as character):
    urlEntry = replace(urlEntry, '%20', ' ').
    return urlEntry.
  end method.  // urlDecode
  
  
  method private void reset():
    delete object this-object:queryParameters no-error.  
  end method.  // reset
  
  
  method private void extractHttpInfo(request as IWebRequest):
    
    define variable parameters as character no-undo.
    define variable parameterCount as integer no-undo.
    define variable i as integer no-undo.
    define variable currentEntry as character no-undo.
    define variable parameterName as character no-undo.
    define variable parameterValue as character no-undo.
    
    this-object:queryParameters = new StringStringMap().
  
    parameters = request:GetContextValue('QUERY_STRING').
    
    parameterCount = num-entries(parameters, '&').
    do i = 1 to parameterCount:
      currentEntry = entry(i, parameters, '&').
      parameterName = entry(1, currentEntry, '=').
      parameterValue = this-object:urlDecode(entry(2, currentEntry, '=')).
      this-object:queryParameters:Put(parameterName, parameterValue).
    end.
        
  end method.  // extractHttpInfo
  
  
  method private JsonArray customersToJson(request as IWebRequest):
    
    define variable json as JsonArray no-undo.
    define variable recordJson as JsonObject no-undo.
    
    define variable queryHandle as handle no-undo.
    define variable bufferHandle as handle no-undo.
    define variable i as integer no-undo.
    define variable id as character no-undo.
    
    json = new JsonArray().
    
    id = this-object:queryParameters:Get('id').
    
    create query queryHandle.
    create buffer bufferHandle for table 'customer'.
    queryHandle:set-buffers(bufferHandle).
    queryHandle:query-prepare('for each customer' + if (id > '') then ' where custnum = ' + quoter(id) else '').
    queryHandle:query-open().
    
    queryHandle:get-first().
    do while (not queryHandle:query-off-end):
      recordJson = new JsonObject().
      do i = 1 to bufferHandle:num-fields:
        recordJson:Add(bufferHandle:buffer-field(i):name, bufferHandle:buffer-field(i):buffer-value).
      end.
      json:Add(recordJson).
      queryHandle:get-next().  
    end.
    
    return json.
    
    finally:
       delete object queryHandle no-error.
       delete object bufferHandle no-error.    
    end finally.
    
  end method.  // customersToJson

  
  /* this method is a copy of the one in HttpHelper. The copy here is to make
   * this handler dependy free, other than OpenEdge.* and Progress.*
   */
  method private character normalizeHeaderName(headerName as character):
    
    define variable nextCharUpper as logical no-undo.
    define variable resultString as character no-undo.
    define variable headerNameLength as integer no-undo.
    define variable i as integer no-undo.
    define variable currentChar as character no-undo.
    
    headerNameLength = length(headerName).
    nextCharUpper = true.
    do i = 1 to headerNameLength:
      
      currentChar = substring(headerName, i, 1).

      if (nextCharUpper) then do:
        resultString = resultString + caps(currentChar).
        nextCharUpper = false.
        next.
      end.  
      
      if (currentChar = '_') then
        currentChar = '-'.
      
      if (currentChar = '-') then
        nextCharUpper = true.        
      
      resultString = resultString + lc(currentChar).
      
    end.
    
    return resultString.
    
  end method.  // normalizeHeaderName
  
  
  method public static int64 stringToNumber(numberString as character):
    
    var char digits = "0123456789".
    var char postfix.
    var int strlen.
    var int i.
    var char c.
    var int64 result.
    
    strlen = length(numberString).
    do i = 1 to strlen:
      c = substring(numberString, i, 1).
      if (index(digits, c) > 0) then 
        result = (result * 10) + int(c).
      else
        postfix += c.
    end.
    
    case (postfix):
      when "" then .
      when "k" then result *= 1000.
      when "Ki" then result *= 1024.
      when "M" then result *= 1000 * 1000.
      when "Mi" then result *= 1024 * 1024.
      when "G" then result *= 1000 * 1000 * 1000.
      when "Gi" then result *= 1024 * 1024 * 1024.
      when "T" then result *= 1000 * 1000 * 1000 * 1000.
      when "Ti" then result *= 1024 * 1024 * 1024 * 1024.
      otherwise undo, throw new AppError(substitute("'&1' is not a valid postfix", postfix), -1).
    end case.
    
    return result.
    
  end method.  //stringToNumber
    
end class.
    