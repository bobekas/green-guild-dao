import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export interface Account {
  'owner' : Principal,
  'subaccount' : [] | [Subaccount],
}
export interface DAO {
  'addGoal' : ActorMethod<[string], undefined>,
  'addMember' : ActorMethod<[Member], Result>,
  'balanceOf' : ActorMethod<[Account], bigint>,
  'getAllMembers' : ActorMethod<[], Array<Member>>,
  'getGoals' : ActorMethod<[], Array<string>>,
  'getManifesto' : ActorMethod<[], string>,
  'getMember' : ActorMethod<[Principal], Result_1>,
  'getName' : ActorMethod<[], string>,
  'mint' : ActorMethod<[Principal, bigint], undefined>,
  'numberOfMembers' : ActorMethod<[], bigint>,
  'removeMember' : ActorMethod<[], Result>,
  'setManifesto' : ActorMethod<[string], undefined>,
  'tokenName' : ActorMethod<[], string>,
  'tokenSymbol' : ActorMethod<[], string>,
  'totalSupply' : ActorMethod<[], bigint>,
  'transfer' : ActorMethod<[Account, Account, bigint], Result>,
  'updateMember' : ActorMethod<[Member], Result>,
}
export interface Member { 'age' : bigint, 'name' : string }
export type Result = { 'ok' : null } |
  { 'err' : string };
export type Result_1 = { 'ok' : Member } |
  { 'err' : string };
export type Subaccount = Uint8Array | number[];
export interface _SERVICE extends DAO {}
