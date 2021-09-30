// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {

  address public owner;

  uint public skuCount;

  mapping (uint => Item) items;

  enum State { ForSale, Sold, Shipped, Received }

  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }
  
  /* 
   * Events
   */

  event LogForSale(uint sku);

  event LogSold(uint sku);

  event LogShipped(uint sku);

  event LogReceived(uint sku);

  /* 
   * Modifiers
   */

  modifier isOwner(address _address) {
    require (msg.sender == owner);
    _;
  }

  modifier verifySeller (uint _sku) {
    require(msg.sender == items[_sku].seller);
    _;
  }

  modifier verifyBuyer (uint _sku) {
    require(msg.sender == items[_sku].buyer);
    _;
  }

  modifier paidEnough(uint _sku) { 
    require(msg.value >= items[_sku].price); 
    _;
  }

  modifier checkValue(uint _sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;

    if (amountToRefund > 0) {
      items[_sku].buyer.call.value(amountToRefund)("");
    }
  }

  modifier forSale(uint sku) {
    require(items[sku].state == State.ForSale);
    require(items[sku].price > 0);
    _;
  }
  
  modifier sold(uint sku) {
    require(items[sku].state == State.Sold);
    _;
  }
  
  modifier shipped(uint sku) {
    require(items[sku].state == State.Shipped);
    _;
  }

  constructor () public {
    owner = msg.sender;
    skuCount = 0;
  }

  function addItem(string memory _name, uint _price) public {
    items[skuCount] = Item({
      name: _name,
      sku: skuCount,
      price: _price,
      state: State.ForSale,
      seller: msg.sender,
      buyer: address(0)
    });

    emit LogForSale(skuCount);

    skuCount = skuCount + 1;
  }

  function buyItem(uint sku) public payable forSale(sku) paidEnough(sku) checkValue(sku) {
    (bool success,) = items[sku].seller.call.value(items[sku].price)("");
    
    if (success) {
      items[sku].buyer = msg.sender;
      items[sku].state = State.Sold;

      emit LogSold(sku);
    }
  }

  function shipItem(uint sku) public sold(sku) verifySeller(sku) {
    items[sku].state = State.Shipped;

    emit LogShipped(sku);
  }

  function receiveItem(uint sku) public shipped(sku) verifyBuyer(sku) {
    items[sku].state = State.Received;

    emit LogReceived(sku);
  }

  function fetchItem(uint _sku) public view
    returns (string memory name, uint sku, uint price, uint state, address seller, address buyer)
  {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
  }
}
