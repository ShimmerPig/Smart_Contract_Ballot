pragma solidity ^0.4.11;

contract Ballot {
  //投票人，其属性包括 uint weight（该投票人的权重）、bool voted（是否已投票）、
  //address delegate（如果该投票人将投票委托给他人，则记录受委托人的账户地址）和
  //uint vote（投票做出的选择，即相应提案的索引号）
  struct Voter{
    uint weight;
    bool voted;
    address delegate;
    uint vote;
  }

  //提案，其属性包括 bytes32 name（名称）和 uint voteCount（已获得的票数）
  struct Proposal{
    bytes32 name;
    uint voteCount;
  }

  //投票发起人，类型为 address
  address public chairperson;
  //所有投票人，类型为 address 到 Voter 的映射
  mapping (address => Voter) public voters;
  //所有提案，类型为动态大小的 Proposal 数组
  Proposal[] public proposals;

  //函数 function Ballot(bytes32[] proposalNames) 用于创建一个新的投票
  function Ballot(bytes32[] proposalNames) {
    //同时用 msg.sender 获取当前调用消息的发送者的地址，记录为投票发起人 chairperson，该发起人投票权重设为 1
    chairperson=msg.sender;
    voters[chairperson].weight=1;

    //所有提案的名称通过参数 bytes32[] proposalNames 传入，逐个记录到状态变量 proposals 中
    for(uint i=0;i<proposalNames.length;i++){
      proposals.push(Proposal({
        name:proposalNames[i],
        voteCount:0
        }));
    }
  }

  //函数 function giveRightToVote(address voter) 实现给投票人赋予投票权
  function giveRightToVote(address voter) {
    //这个函数只有投票发起人 chairperson 可以调用。这里用到了 require((msg.sender == chairperson) && !voters[voter].voted)
    //函数。如果 require 中表达式结果为 false，这次调用会中止，且回滚所有状态和以太币余额的改变到调用前。但已消耗的 Gas 不会返还
    require((msg.sender == chairperson) && !voters[voter].voted);
    //该函数给 address voter 赋予投票权，即将 voter 的投票权重设为 1，存入 voters 状态变量
    voters[voter].weight=1;
  }

  //函数 function delegate(address to) 把投票委托给其他投票人
  function delegate(address to) {
    //用 voters[msg.sender] 获取委托人，即此次调用的发起人
    Voter sender=voters[msg.sender];
    //用 require 确保发起人没有投过票，且不是委托给自己
    require(!sender.voted);
    require(to!=msg.sender);

    //由于被委托人也可能已将投票委托出去，所以接下来，用 while 循环查找最终的投票代表
    while(voters[to].delegate!=address(0)){
      to=voters[to].delegate;
      require(to!=msg.sender);
    }

    //找到后，如果投票代表已投票，则将委托人的权重加到所投的提案上；如果投票代表还未投票，则将委托人的权重加到代表的权重上
    sender.voted=true;
    sender.delegate=to;
    Voter delegate=voters[to];
    if(delegate.voted){
      proposals[delegate.vote].voteCount+=sender.weight;
    }else{
      delegate.weight+=sender.weight;
    }
  }

  //函数 function vote(uint proposal) 实现投票过程
  function vote(uint proposal) {
    //用 voters[msg.sender] 获取投票人，即此次调用的发起人
    Voter sender=voters[msg.sender];
    //接下来检查是否是重复投票，如果不是，进行投票后相关状态变量的更新
    require(!sender.voted);
    sender.voted=true;
    sender.vote=proposal;

    proposals[proposal].voteCount+=sender.weight;
  }

  //函数 function winningProposal() constant returns (uint winningProposal) 将返回获胜提案的索引号
  //这里，returns (uint winningProposal) 指定了函数的返回值类型，constant 表示该函数不会改变合约状态变量的值
  function winningProposal() constant returns (uint winningProposal) {
    uint winningVoteCount=0;
    //函数通过遍历所有提案进行记票，得到获胜提案
    for(uint p=0;p<proposals.length;p++){
      if(proposals[p].voteCount>winningVoteCount){
        winningVoteCount=proposals[p].voteCount;
        winningProposal=p;
      }
    }
  }

  //函数 function winnerName() constant returns (bytes32 winnerName) 实现返回获胜者的名称
  function winnerName() constant returns (bytes32 winnerName) {
    //这里采用内部调用 winningProposal() 函数的方式获得获胜提案。如果需要采用外部调用，则需要写为 this.winningProposal()
    winnerName=proposals[winningProposal()].name;
  }
}