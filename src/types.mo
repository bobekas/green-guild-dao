import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
module {
    public type DAOInfo = {
        name : Text;
        manifesto : Text;
        member : [Text];
        logo : Text;
        numberOfMembers : Nat;
    };

    public type MemberRole = {
        #AssetOwner;
        #Contributor;
        #FinancialSupporter;
        #Volunteer;
    };

    public type Member = {
        name : Text;
        roles : [MemberRole];
    };
    public type Result<A, B> = Result.Result<A, B>;
    public type HashMap<A, B> = HashMap.HashMap<A, B>;

    public type Subaccount = Blob;
    public type Account = {
        owner : Principal;
        subaccount : ?Subaccount;
    };

    public type Status = {
        #Open;
        #Accepted;
        #Rejected;
    };

    public type ProposalType = {
        #DecisionMaking;
        #DocumentManagement;
        #Newcomer;
        // TODO: #FundsTransfer
        // TODO: #RolesUpdate
    };

    public type Proposal = {
        id : Nat;
        createdBy : Principal;
        proposalType : ProposalType;
        description : Text;
        status : Status;
        instruction : ?Text;
        votes : Int;
        voters : [Principal];
        // TODO: endsAt 
    };

    public type CreateProposalOk = Nat;

    public type CreateProposalErr = {
        #NotAllowed;
        #NotDAOMember;
        #InstructionRequired;
    };

    public type CreateProposalResult = Result<CreateProposalOk, CreateProposalErr>;

    public type VoteOk = {
        #ProposalAccepted;
        #ProposalRefused;
        #ProposalOpen;
    };

    public type VoteErr = {
        #ProposalNotFound;
        #AlreadyVoted;
        #ProposalEnded;
        #NotEnoughTokens;
        #NotDAOMember;
        #NotAllowed;
    };

    public type VoteResult = Result<VoteOk, VoteErr>;

};
