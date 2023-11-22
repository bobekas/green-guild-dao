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
import Account "account";

actor class DAO() = this {
  public type Result<Ok, Err> = Result.Result<Ok, Err>;
  public type HashMap<K, V> = HashMap.HashMap<K, V>;
  public type TrieMap<K, V> = TrieMap.TrieMap<K, V>;

  public type Member = {
    name : Text;
    age : Nat;
  };

  public type Subaccount = Blob;
  public type Account = {
      owner : Principal;
      subaccount : ?Subaccount;
  };

  public type Status =  {
    #Open;
    #Accepted;
    #Rejected;
  };

  public type Proposal = {
    id : Nat;
    status : Status;
    manifest : Text;
    votes : Int;
    voters : [Principal];
  };

  public type CreateProposalOk = Nat;

  public type CreateProposalErr = {
    #NotDAOMember;
    #NotEnoughTokens;
    #NotImplemented; // This is just a placeholder - can be removed once you start Level 4
  };

  public type createProposalResult = Result<CreateProposalOk, CreateProposalErr>;

  public type VoteOk = {
    #ProposalAccepted;
    #ProposalRefused;
    #ProposalOpen;
  };

  public type VoteErr = {
    #ProposalNotFound;
    #AlreadyVoted;
    #ProposalEnded;
    #NotImplemented; // This is just a placeholder - can be removed once you start Level 4
  };

  public type voteResult = Result<VoteOk, VoteErr>;

  let name : Text = "GreenGuild";
  var manifesto : Text = "";
  var goals = Buffer.Buffer<Text>(1);

  let members : HashMap<Principal, Member> = HashMap.HashMap<Principal, Member>(10, Principal.equal, Principal.hash);

  let ledger : HashMap<Account, Nat> = HashMap.HashMap<Account, Nat>(10, Account.accountsEqual, Account.accountsHash);
  var totalSupplyValue : Nat = 0;

  let proposals : TrieMap<Nat, Proposal> = TrieMap.TrieMap<Nat, Proposal>(10, );
  var nextProposalId : Nat = 0;

  // START - Meta functions
  public query func getName() : async Text {
    "GreenGuild";
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
  }
  // END - Member functions
};