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
import Blob "mo:base/Blob";
import IterType "mo:base/IterType";
import Account "account";
import Types "./types";
import Logo "./logo";

actor class DAO() = this {
  public type Result<Ok, Err> = Result.Result<Ok, Err>;
  public type HashMap<K, V> = HashMap.HashMap<K, V>;
  public type TrieMap<K, V> = TrieMap.TrieMap<K, V>;

  public type DAOInfo = Types.DAOInfo;
  public type MemberRole = Types.MemberRole;
  public type Member = Types.Member;

  public type Subaccount = Types.Subaccount;
  public type Account = Types.Account;

  public type Status =  Types.Status;
  public type Proposal = Types.Proposal;
  public type ProposalType = Types.ProposalType;

  public type CreateProposalOk = Types.CreateProposalOk;
  public type CreateProposalErr = Types.CreateProposalErr;
  public type CreateProposalResult = Types.CreateProposalResult;

  public type VoteOk = Types.VoteOk;
  public type VoteErr = Types.VoteErr;
  public type VoteResult = Types.VoteResult;

  let name : Text = "Green Guild";
  var manifesto : Text = "GreenGuild envisions a harmonious blend of community living and sustainable practices, driven by innovative technology.";

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

  public query func getStats() : async DAOInfo {
    let data : DAOInfo = {
      name = name;
      manifesto = manifesto;
      member = _getMemberNames();
      logo = logo;
      numberOfMembers = members.size();
    };

    return data;
  };
  // END - Meta functions

  // START - Ledger functions
  // ТОДО: Depricate and remove after Ledger Canister integration
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
  public shared ({ caller }) func createContributeMember(name : Text) : async Result<(), Text> {
    //Check if caller is not anoymous
    // if(Principal.equal(caller, Principal.fromText("2vxsx-fae"))) {
    //   return #err("Anonymous users are not allowed to add members.");
    // };

    // TODO: Validate that the member is locked in 1 ICP
    if(false) {
      return #err("Lock 1 ICP to become a member");
    };

    let memberResult = members.get(caller);

    //If member already exists:
    // Case 1 - If Volunteer update it to Contributor
    // Case 2 - Otherwise Return error
    switch(memberResult) {
      case(null) {};
      case(?m) {
        if(m.roles.size() == 1 and m.roles[0] == #Volunteer) {
          members.put(caller, {
            name = name;
            roles = [#Contributor];
          });

          return #ok;
        } else {
          return #err("A member with the same identifier already exists.");
        };
      };
    };

    // Check for open Newcomer proposal, if exists -> #Reject
    let newcomerProposalsResult : ?(Nat, Proposal) = Iter.filter(proposals.entries(), func(a : (Nat, Proposal)) : Bool { a.1.createdBy == caller and a.1.proposalType == #Newcomer; }).next();

    switch(newcomerProposalsResult) {
      case(null) {

      };
      case(?newcomerProposalsResult) {
        let updatedProposal : Proposal = {
          id = newcomerProposalsResult.1.id;
          createdBy = newcomerProposalsResult.1.createdBy;
          status = #Rejected;
          description = newcomerProposalsResult.1.description;
          proposalType = newcomerProposalsResult.1.proposalType;
          instruction = newcomerProposalsResult.1.instruction;
          votes = newcomerProposalsResult.1.votes;
          voters = newcomerProposalsResult.1.voters;
        };

        proposals.put(newcomerProposalsResult.0, updatedProposal);
      };
    };

    let member = _createMember(name, caller, [#Contributor]);

    return #ok;
  };

  public shared ({ caller}) func createNewcomerProposal(name : Text) : async Result<(), Text> {
    if(members.get(caller) != null) {
      return #err("A member with the same identifier already exists.");
    };

    let proposalsIter = proposals.vals();
    let existingNewcomerProposal = Iter.filter<(Proposal)>(proposalsIter, func (item : Proposal) : Bool {
      item.createdBy == caller and item.proposalType == #Newcomer;
    });

    switch(existingNewcomerProposal.next()) {
      case(null) {
      };
      case(_) {
        return #err("Newcomer proposal already exists.");
      };
    };

    let proposal = _createNewProposal(#Newcomer, name # " wants to join as a volunteer.", caller, ?name);

    return #ok();
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

  // This function clears all roles of a member
  public shared ({ caller }) func removeMember() : async Result<(), Text> {
    let memberData : ?Member = members.get(caller);

    switch (memberData) {
      case (null) {
        return #err("Member not found.");
      };
      case (?member) {
        let a : Member = {
          name = member.name;
          roles = [];
        };

        members.put(caller, a);

        return #ok();
      };
    };

    return #ok();
  };
  // END - Member functions

  // START - Proposal functions
  public shared ({ caller }) func createProposal(proposalType : ProposalType, description : Text, instruction : ?Text) : async CreateProposalResult {
    let member = members.get(caller);

    // Check if the caller is a DAO member
    switch(member) {
      case(null) {
        return #err(#NotDAOMember);
      };
      case(?m) {
        // If Volunteer return error
        if(Array.find<MemberRole>(m.roles, func x = x == #Volunteer) != null) {
          return #err(#NotAllowed);
        }
      };
    };

    // Check if instruction is required but not provided
    if (_isInstructionRequired(proposalType) and instruction == null) {
        return #err(#InstructionRequired);
    };

    // Check if the caller has at least 1 token
    let callerAccount : Account = {
      owner = caller;
      subaccount = null;
    };

    let proposal = _createNewProposal(proposalType, description, caller, instruction);

    // Return success with the new proposal's ID
    return #ok(proposal.id);
  };

  public query func getAllProposals() : async [(Nat, Proposal)] {
    let entries = proposals.entries();

    return Iter.toArray<(Nat, Proposal)>(entries);
  };

  public query func getProposal(id : Nat) : async ?Proposal {
    // Retrieve the proposal using the given ID
    return proposals.get(id);
  };

  public shared ({ caller }) func vote(id : Nat, vote : Bool) : async VoteResult {
    let member = members.get(caller);

    // Check if the caller is a DAO member
    switch(member) {
      case(null) {
        return #err(#NotDAOMember);
      };
      case(?m) {
        // If Volunteer return error
        if(Array.find<MemberRole>(m.roles, func x = x == #Volunteer) != null) {
          return #err(#NotAllowed);
        }
      };
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

        // TODO: Voting power based on member score...

        // Process the vote
        let voteChange = if (vote) { 1 } else { -1 };
        let updatedVotes = Int.add(proposal.votes, voteChange);
        let updatedVoters = Array.append<Principal>(proposal.voters, [caller]);
        var updatedStatus : Status = proposal.status;

        let majorityRequired = members.size() / 2; // More than 50%

        // Update vote status
        if (updatedVotes > majorityRequired) { // Assuming 10 votes are needed for acceptance
          updatedStatus := #Accepted;
        } else if (Int.abs(updatedVotes) >= majorityRequired) { // Assuming -10 votes for refusal
          updatedStatus := #Rejected;
        };

        let updatedProposal : Proposal = {
          id = proposal.id;
          createdBy = proposal.createdBy;
          status = updatedStatus;
          description = proposal.description;
          proposalType = proposal.proposalType;
          instruction = proposal.instruction;
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
            // TODO:
            // Use a "Commit Point" variable to indicate whether the proposal's instructions have been executed. 
            // This will help prevent issues related to transaction failures or traps in the system.
            switch(proposal.proposalType) {
              case(#Newcomer) {
                let member = _createMember(Option.get(proposal.instruction, "Unknown"), proposal.createdBy, [#Volunteer]);
              };
              case(_) {

              };
            };
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

  // Helper function to determine if instruction is required for a proposal type
  private func _isInstructionRequired(proposalType: ProposalType): Bool {
    return proposalType == #DocumentManagement;
  };

  private func _createMember(name : Text, memberPrincipal : Principal, roles : [MemberRole]) : Member {
    let member : Member = {
      name = name;
      roles = roles;
    };

    members.put(memberPrincipal, member);

    return member;
  };

  private func _createNewProposal(proposalType : ProposalType, description : Text, createdBy : Principal, instruction : ?Text) : Proposal {
    // Create a new proposal
    let proposalId = nextProposalId;
    let newProposal: Proposal = {
        id = proposalId;
        createdBy = createdBy;
        proposalType = proposalType;
        description = description;
        status = #Open;
        instruction = instruction;
        votes = 0;
        voters = [];
    };

    // Store the proposal
    proposals.put(proposalId, newProposal);

    // Increment the nextProposalId
    nextProposalId := Nat.add(nextProposalId, 1);

    return newProposal;
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
};