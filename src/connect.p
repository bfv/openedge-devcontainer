
// for each customer no-lock:
//     message customer.custnum customer.name.
// end.


for customer where Customer.CustNum = 3000 no-lock:
    message "FIRST:" customer.custnum customer.name. 
end.

message "OUTER:" customer.custnum customer.name. 

message "done".
