# Ethereum Ticket System
Ticket booking system that issues tickets as NFTs to customers by using smart contracts on the Ethereum blockchain.

## Modeling and scoping
A TicketBookingSystem instance is modelled as a show with the same show title, the same 
seat layout, the same prices for each row and a set of available timestamps. The instance is 
therefore not constrained to one specific date and time, and can be re-used multiple times. 

Each tokenID is unique for each show title, timestamp, row number and seat number. This is 
done by exploiting the fact that the tokenID is 256 bits long. This means that the 160-bit 
TicketBookingSystem address (which uniquely represents a show title), a 40-bit timestamp
field, a 16-bit row number and a 16-bit seat number can all be encoded inside the tokenID. 
The link, a string, can then easily be passed and retrieved from the data field in the 
ticket by simply translating between string and bytes32. It is assumed that the link contains
all the information about the seat and timestamp, but we concluded that encoding the link
with this info was out of scope for the task.

We've thought of the system as an API to the ticket system backend, and hence, the input 
formats are efficient but not that user friendly. E.g., unix for timestamps.  

TokenID format:
>24 zeros + 16-bit seat number + 16-bit seat row number + 40-bit timestamp + 160-bit show ID  

## Trading Functionality 
Trading is implemented by letting one person put their token up for sale or trade by 
calling the putOnMarket function, and then let a buyer call tradeTicket to attemt to trade
or buy a function from the market. This will be successful if the buyer either provides the 
requested amount or ticket specified by the seller, and the requested ticket from the buyer
is on the marketplace already.

