import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import TrieMap "mo:base/TrieMap";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Account "account";
import Types "./types";
import Logo "./logo";

actor class DAO() = this {
  public type Result<Ok, Err> = Result.Result<Ok, Err>;
  public type HashMap<K, V> = HashMap.HashMap<K, V>;
  public type TrieMap<K, V> = TrieMap.TrieMap<K, V>;

  public type DAOInfo = Types.DAOInfo;
  public type Member = Types.Member;

  public type Subaccount = Types.Subaccount;
  public type Account = Types.Account;

  public type Status =  Types.Status;
  public type Proposal = Types.Proposal;

  public type CreateProposalOk = Types.CreateProposalOk;
  public type CreateProposalErr = Types.CreateProposalErr;
  public type CreateProposalResult = Types.CreateProposalResult;

  public type VoteOk = Types.VoteOk;
  public type VoteErr = Types.VoteErr;
  public type VoteResult = Types.VoteResult;

  let name : Text = "GreenGuild";
  var manifesto : Text = "";
  var goals = Buffer.Buffer<Text>(1);

  var logo : Text = Logo.getSvg();

  let members : HashMap<Principal, Member> = HashMap.HashMap<Principal, Member>(10, Principal.equal, Principal.hash);

  let ledger : HashMap<Account, Nat> = HashMap.HashMap<Account, Nat>(10, Account.accountsEqual, Account.accountsHash);
  var totalSupplyValue : Nat = 0;

  let proposals : TrieMap<Nat, Proposal> = TrieMap.TrieMap<Nat, Proposal>(Nat.equal, Hash.hash);
  var nextProposalId : Nat = 0;

  // START - Meta functions
  public query func getName() : async Text {
    return name;
  };

  public query func getManifesto() : async Text {
    return manifesto;
  };

  public func setManifesto(value : Text) : async () {
    manifesto := value;
  };

  public func addGoal(value : Text) : async () {
    goals.add(value);
  };

  public query func getGoals() : async [Text] {
    return Buffer.toArray<Text>(goals);
  };

  public query func getStats() : async DAOInfo {
    let data : DAOInfo = {
      name = name;
      manifesto = manifesto;
      goals = Buffer.toArray<Text>(goals);
      member = _getMemberNames();
      logo = logo;
      numberOfMembers = members.size();
    };

    return data;
  };
  // END - Meta functions

  // START - Ledger functions
  public query func tokenName() : async Text {
    return "Eco Credits";
  };

  public query func tokenSymbol() : async Text {
    return "ECR";
  };

  public func mint(principal : Principal, amount : Nat) : async () {
    let defaultAccount : Account = {
      owner = principal;
      subaccount = null;
    };

    let currentBalance = Option.get(ledger.get(defaultAccount), 0);

    ledger.put(defaultAccount, Nat.add(currentBalance, amount));

    // Update total supply value
    totalSupplyValue := Nat.add(totalSupplyValue, amount);
  };

  //Transfers a specified amount from the 'from' account to the 'to' account.
  public func transfer(from: Account, to: Account, amount: Nat) : async Result<(), Text> {
    let senderBalance = ledger.get(from);

    switch (senderBalance) {
      case (null) {
        return #err("Sender's account does not exist.");
      };
      case (?balance) {
        if (Nat.less(balance, amount)) {
          return #err("Insufficient funds in sender's account.");
        } else {
          // Subtract amount from sender's account
          ledger.put(from, Nat.sub(balance, amount));

          // Get recipient's balance
          let recipientBalance = Option.get(ledger.get(to), 0);

          ledger.put(to, Nat.add(recipientBalance, amount));

          return #ok();
        };
      };
    };
  };

  public query func balanceOf(account : Account) : async Nat {
    return Option.get(ledger.get(account), 0);
  };

  public query func totalSupply() : async Nat {
    return totalSupplyValue;
  };
  // END - Ledger functions

  // START - Member functions
  public shared ({ caller }) func addMember(member : Member) : async Result<(), Text> {
    //Check if caller is not anoymous
    // if(Principal.equal(caller, Principal.fromText("2vxsx-fae"))) {
    //   return #err("Anonymous users are not allowed to add members.");
    // };

    if(members.get(caller) != null) {
      return #err("A member with the same identifier already exists.");
    };

    members.put(caller, member);

    return #ok;
  };

  public query func getMember(principal : Principal) : async Result<Member, Text> {
    let memberData : ?Member = members.get(principal);

    switch (memberData) {
      case (null) {
        return #err("Member not found.");
      };
      case (?member) {
        return #ok(member);
      };
    };
  };

  public shared ({ caller }) func updateMember(updatedMemberData : Member) : async Result<(), Text> {
    let memberData : ?Member = members.get(caller);

    switch (memberData) {
      case (null) {
        return #err("Member not found.");
      };
      case (?member) {
        members.put(caller, updatedMemberData);

        return #ok();
      };
    };
  };

  public query func getAllMembers() : async [Member] {
    let entries = members.entries();
    let memberIter : Iter.Iter<Member> = {
      next = func () : ?Member {
        switch (entries.next()) {
          case (?(_, member)) { return ?member; };
          case null { return null; };
        };
      };
    };

    return Iter.toArray<Member>(memberIter);
  };

  private func _getMemberNames() : [Text] {
    let entries = members.entries();
    let memberIter : Iter.Iter<Text> = {
      next = func () : ?Text {
        switch (entries.next()) {
          case (?(_, member)) {
            return ?member.name;
          };
          case null { return null; };
        };
      };
    };

    return Iter.toArray<Text>(memberIter);
  };

  public query func numberOfMembers() : async Nat {
    return members.size();
  };

  public shared ({ caller }) func removeMember() : async Result<(), Text> {
    //Check if caller is not anoymous
    // if(Principal.equal(caller, Principal.fromText("2vxsx-fae"))) {
    //   return #err("Anonymous users are not allowed to remove members.");
    // };

    members.delete(caller);

    return #ok();
  };
  // END - Member functions

  // START - Proposal functions
  public shared ({ caller }) func createProposal(manifest : Text) : async CreateProposalResult {
    // Check if the caller is a DAO member
    if (members.get(caller) == null) {
      return #err(#NotDAOMember);
    };

    // Check if the caller has at least 1 token
    let callerAccount : Account = {
      owner = caller;
      subaccount = null;
    };

    let callerBalance = Option.get(ledger.get(callerAccount), 0);
    if (callerBalance < 1) {
      return #err(#NotEnoughTokens);
    };

    // Deduct 1 token for creating a proposal (burning it)
    ledger.put(callerAccount, Nat.sub(callerBalance, 1));
    totalSupplyValue := Nat.sub(totalSupplyValue, 1);

    // Create a new proposal
    let proposalId = nextProposalId;
    let newProposal : Proposal = {
      id = proposalId;
      status = #Open;
      manifest = manifest;
      votes = 0;
      voters = [];
    };

    // Store the proposal
    proposals.put(proposalId, newProposal);

    // Increment the nextProposalId
    nextProposalId := Nat.add(nextProposalId, 1);

    // Return success with the new proposal's ID
    return #ok(proposalId);
  };

  public query func getProposal(id : Nat) : async ?Proposal {
    // Retrieve the proposal using the given ID
    return proposals.get(id);
  };

  public shared ({ caller }) func vote(id : Nat, vote : Bool) : async VoteResult {
    // Check if the caller is a DAO member
    if (members.get(caller) == null) {
      return #err(#NotDAOMember);
    };

    // Retrieve the proposal
    switch (proposals.get(id)) {
      case (null) {
        // Proposal not found
        return #err(#ProposalNotFound);
      };
      case (?proposal) {
        // Check if the proposal is still open
        if (proposal.status != #Open) {
          return #err(#ProposalEnded);
        };
        
        // Check if the caller has already voted
        if (Array.indexOf<Principal>(caller, proposal.voters, Principal.equal) != null) {
          return #err(#AlreadyVoted);
        };

        // Check if the caller has at least 1 token
        let callerAccount : Account = {
          owner = caller;
          subaccount = null;
        };

        let callerBalance = Option.get(ledger.get(callerAccount), 0);
        if (callerBalance < 1) {
          return #err(#NotEnoughTokens);
        };

        // Process the vote
        let voteChange = if (vote) { 1 } else { -1 };
        let updatedVotes = Int.add(proposal.votes, voteChange);
        let updatedVoters = Array.append<Principal>(proposal.voters, [caller]);
        var updatedStatus : Status = proposal.status;

        // Burn 1 token for voting
        ledger.put(callerAccount, Nat.sub(callerBalance, 1));
        totalSupplyValue := Nat.sub(totalSupplyValue, 1);

        // Update vote status
        if (updatedVotes >= 10) { // Assuming 10 votes are needed for acceptance
          updatedStatus := #Accepted;
        } else if (updatedVotes <= -10) { // Assuming -10 votes for refusal
          updatedStatus := #Rejected;
        };

        let updatedProposal : Proposal = {
          id = proposal.id;
          status = updatedStatus;
          manifest = proposal.manifest;
          votes = updatedVotes;
          voters = updatedVoters;
        };

        proposals.put(updatedProposal.id, updatedProposal);

        // Return vote result
        switch(updatedStatus) {
          case(#Open) {
            return #ok(#ProposalOpen);
          };
          case(#Accepted) {
            // Update DAO's manifesto
            manifesto := proposal.manifest;
            
            return #ok(#ProposalAccepted);
          };
          case(#Rejected) {
            return #ok(#ProposalRefused)
          };
        };
      };
    };
  };
  // END - Proposal functions

  public shared ({ caller }) func whoami() : async Principal {
    caller;
  };
};