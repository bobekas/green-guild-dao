export const idlFactory = ({ IDL }) => {
  const Member = IDL.Record({ 'age' : IDL.Nat, 'name' : IDL.Text });
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Text });
  const Subaccount = IDL.Vec(IDL.Nat8);
  const Account = IDL.Record({
    'owner' : IDL.Principal,
    'subaccount' : IDL.Opt(Subaccount),
  });
  const Result_1 = IDL.Variant({ 'ok' : Member, 'err' : IDL.Text });
  const DAO = IDL.Service({
    'addGoal' : IDL.Func([IDL.Text], [], []),
    'addMember' : IDL.Func([Member], [Result], []),
    'balanceOf' : IDL.Func([Account], [IDL.Nat], ['query']),
    'getAllMembers' : IDL.Func([], [IDL.Vec(Member)], ['query']),
    'getGoals' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'getManifesto' : IDL.Func([], [IDL.Text], ['query']),
    'getMember' : IDL.Func([IDL.Principal], [Result_1], ['query']),
    'getName' : IDL.Func([], [IDL.Text], ['query']),
    'mint' : IDL.Func([IDL.Principal, IDL.Nat], [], []),
    'numberOfMembers' : IDL.Func([], [IDL.Nat], ['query']),
    'removeMember' : IDL.Func([], [Result], []),
    'setManifesto' : IDL.Func([IDL.Text], [], []),
    'tokenName' : IDL.Func([], [IDL.Text], ['query']),
    'tokenSymbol' : IDL.Func([], [IDL.Text], ['query']),
    'totalSupply' : IDL.Func([], [IDL.Nat], ['query']),
    'transfer' : IDL.Func([Account, Account, IDL.Nat], [Result], []),
    'updateMember' : IDL.Func([Member], [Result], []),
  });
  return DAO;
};
export const init = ({ IDL }) => { return []; };
