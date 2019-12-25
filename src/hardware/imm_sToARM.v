(******************************************************************************)
(** * Compilation correctness from the S_IMM memory model to the ARMv8.3 model *)
(******************************************************************************)

From hahn Require Import Hahn.
Require Import Events.
Require Import Execution.
Require Import Execution_eco.
Require Import Arm.
Require Import imm_bob.
Require Import imm_s_ppo.
Require Import imm_s_hb.
Require Import imm_s.
Require Import imm_ppo.
Require Import imm_hb.
Require Import imm.
Require Import immToARMhelper.

Set Implicit Arguments.
Remove Hints plus_n_O.

Section immToARM.

Variable G : execution.

Notation "'E'" := G.(acts_set).
Notation "'acts'" := G.(acts).
Notation "'lab'" := G.(lab).
Notation "'sb'" := G.(sb).
Notation "'rf'" := G.(rf).
Notation "'co'" := G.(co).
Notation "'rmw'" := G.(rmw).
Notation "'data'" := G.(data).
Notation "'addr'" := G.(addr).
Notation "'ctrl'" := G.(ctrl).
Notation "'deps'" := G.(deps).
Notation "'rmw_dep'" := G.(rmw_dep).

Notation "'fre'" := G.(fre).
Notation "'rfe'" := G.(rfe).
Notation "'coe'" := G.(coe).
Notation "'rfi'" := G.(rfi).
Notation "'fri'" := G.(fri).
Notation "'coi'" := G.(coi).
Notation "'fr'" := G.(fr).
Notation "'eco'" := G.(eco).

Notation "'R'" := (fun a => is_true (is_r lab a)).
Notation "'W'" := (fun a => is_true (is_w lab a)).
Notation "'F'" := (fun a => is_true (is_f lab a)).
Notation "'RW'" := (R ∪₁ W).
Notation "'FR'" := (F ∪₁ R).
Notation "'FW'" := (F ∪₁ W).
Notation "'W_ex'" := (W_ex G).
Notation "'W_ex_acq'" := (W_ex ∩₁ (fun a => is_true (is_xacq lab a))).
Notation "'R_ex'" := (fun a => is_true (R_ex lab a)).

Notation "'loc'" := (loc lab).
Notation "'val'" := (val lab).
Notation "'mod'" := (mod lab).
Notation "'same_loc'" := (same_loc lab).
Notation "'detour'" := G.(detour).
Notation "'bob'" := G.(bob).

(* imm_s *)
Notation "'s_sw'" := G.(imm_s_hb.sw).
Notation "'s_release'" := G.(imm_s_hb.release).
Notation "'s_rs'" := G.(imm_s_hb.rs).
Notation "'s_hb'" := G.(imm_s_hb.hb).
Notation "'s_ppo'" := G.(imm_s_ppo.ppo).
Notation "'s_psc_f'" := G.(imm_s.psc_f).
Notation "'s_psc_base'" := G.(imm_s.psc_base).
Notation "'s_ar_int'" := G.(imm_s_ppo.ar_int).

(* imm *)
Notation "'sw'" := G.(imm_hb.sw).
Notation "'release'" := G.(imm_hb.release).
Notation "'rs'" := G.(imm_hb.rs).
Notation "'hb'" := G.(imm_hb.hb).
Notation "'ppo'" := G.(imm_ppo.ppo).
Notation "'psc'" := G.(imm.psc).
Notation "'psc_f'" := G.(imm.psc_f).
Notation "'psc_base'" := G.(imm.psc_base).
Notation "'ar_int'" := G.(imm_ppo.ar_int).

Notation "'Pln'" := (fun a => is_true (is_only_pln lab a)).
Notation "'Rlx'" := (fun a => is_true (is_rlx lab a)).
Notation "'Rel'" := (fun a => is_true (is_rel lab a)).
Notation "'Acq'" := (fun a => is_true (is_acq lab a)).
Notation "'Acqrel'" := (fun a => is_true (is_acqrel lab a)).
Notation "'Acq/Rel'" := (fun a => is_true (is_ra lab a)).
Notation "'Sc'" := (fun a => is_true (is_sc lab a)).

(* arm *)
Notation "'obs'" := G.(obs).
Notation "'obs''" := G.(obs').
Notation "'aob'" := G.(aob).
Notation "'boba'" := G.(Arm.bob).
Notation "'boba''" := G.(bob').
Notation "'dob'" := G.(dob).

Notation "'L'" := (W ∩₁ (fun a => is_true (is_rel lab a))).
Notation "'Q'" := (R ∩₁ (fun a => is_true (is_acq lab a))).
Notation "'A'" := (R ∩₁ (fun a => is_true (is_sc  lab a))).

Notation "'F^ld'" := (F ∩₁ (fun a => is_true (is_acq lab a))).
Notation "'F^sy'" := (F ∩₁ (fun a => is_true (is_rel lab a))).

Hypothesis RMW_DEPS : rmw ⊆ ctrl ∪ data.
Hypothesis W_EX_ACQ_SB : ⦗W_ex_acq⦘ ⨾ sb ⊆ sb ⨾ ⦗F^ld⦘ ⨾  sb^?.
Hypothesis DEPS_RMW_SB : rmw_dep ⨾ sb ⊆ ctrl.

Hypothesis CON: ArmConsistent G.

Lemma WF : Wf G.
Proof. apply CON. Qed.
Lemma COMP : complete G.
Proof. apply CON. Qed.
Lemma SC_PER_LOC : sc_per_loc G.
Proof. apply CON. Qed.

Lemma rmw_coi_helper : rmw ⨾ coi ⊆ ctrl ;; <|W|> ∪ data ;; coi.
Proof.
  rewrite RMW_DEPS, seq_union_l.
  rewrite (dom_r WF.(wf_coiD)).
  arewrite (coi ⊆ sb) at 1. by sin_rewrite WF.(ctrl_sb).
Qed.

Lemma rmw_coi_helper1 : rmw ⨾ coi^? ⊆ ctrl ∪ data ;; coi^?.
Proof.
  rewrite crE at 1. rewrite seq_union_r, seq_id_r.
  unionL.
  2: { rewrite rmw_coi_helper. basic_solver 10. }
  rewrite RMW_DEPS. basic_solver 10.
Qed.

Lemma RMW_COI : rmw ⨾ coi ⊆ obs ∪ dob ∪ aob ∪ boba.
Proof.
  transitivity dob; [|by eauto with hahn].
  rewrite rmw_coi_helper.
  rewrite (dom_r WF.(wf_dataD)).
  unfold Arm.dob. basic_solver 10.
Qed.

(* Lemma s_ppo_in_obs_dob_helper : *)
(*   ⦗R⦘ ⨾ (data ∪ ctrl ∪ addr ⨾ sb^? ∪ rfi ∪ rmw ;; coi^?)⁺ ⨾ ⦗W⦘ ⊆ (obs' ∪ dob)⁺. *)
(* Proof. *)
(*   rewrite path_union1. *)
(*   assert (transitive rfi). *)
(*   { apply transitiveI. rewrite (wf_rfiD WF). type_solver. } *)
(*   relsf; unionL. *)
(*   { rewrite (wf_rfiD WF). type_solver. } *)
(*   rewrite !seqA. *)
(*   arewrite_id (⦗R⦘ ⨾ rfi^?). *)
(*   { rewrite (wf_rfiD WF). type_solver. } *)
(*   rels. *)
(*   arewrite (data ⨾ coi^? ∪ ctrl ∪ addr ⨾ sb^? ∪ *)
(*                  (data ⨾ coi^? ⨾ rfi ∪ ctrl ⨾ rfi ∪ addr ⨾ sb^? ⨾ rfi) *)
(*             ⊆ (data ⨾ coi^? ∪ ctrl ∪ addr ⨾ sb^?) ⨾ rfi^?) by basic_solver 12. *)
(*   relsf. *)
(*   rewrite unionA. *)
(*   rewrite path_ut_first. rewrite !seqA. *)
(*   arewrite (data ⨾ coi^? ⨾ rfi^? ⊆ (obs' ∪ dob)⁺). *)
(*   { rewrite !crE, !seq_union_l, !seq_union_r, !seq_id_l, !seq_id_r. *)
(*     unionL. *)
(*     1-3: rewrite <- ct_step; unionR right; rewrite (dom_r WF.(wf_dataD)); unfold Arm.dob; *)
(*       basic_solver 10. *)

(*   rewrite (dob_in_sb WF) at 3. *)
(*   rewrite (ctrl_in_sb WF) at 2. *)
(*   rewrite (addr_in_sb WF) at 2. *)
(*   arewrite (rfi ⊆ sb). *)
(*   generalize (@sb_trans G); ins; relsf. *)
(*   rewrite !seqA; relsf. *)
(*   arewrite (ctrl ⨾ sb^? ⊆ ctrl). *)
(*   generalize (ctrl_sb WF); basic_solver 12. *)
(*   arewrite (ctrl ⨾ ⦗W⦘⊆ dob). *)
(*   unfold Arm.dob; basic_solver 12. *)

(*   arewrite ( addr ⨾ sb^? ⨾ ⦗W⦘⊆ dob). *)
(*   unfold Arm.dob; basic_solver 12. *)

(*   rewrite <- ct_end; basic_solver. *)
(* Qed. *)

Lemma s_ppo_in_dob : s_ppo ⊆ dob⁺.
Proof.
  unfold imm_s_ppo.ppo.
  arewrite (data ∪ ctrl ∪ addr ⨾ sb^? ∪ rfi ∪ rmw ⊆ data ∪ ctrl ∪ addr ⨾ sb^? ∪ rfi).
  { rewrite RMW_DEPS. eauto with hahn. }
  rewrite path_union, !seq_union_l, !seq_union_r. unionL.
  { apply ppo_in_dob_helper; auto. }
  assert ((data ∪ ctrl ∪ addr ⨾ sb^? ∪ rfi)＊ ⊆ sb^?) as AA.
  { rewrite WF.(data_in_sb), WF.(ctrl_in_sb), WF.(addr_in_sb).
    arewrite (rfi ⊆ sb).
    generalize (@sb_trans G). ins. relsf. }
  rewrite AA at 2.
  rewrite ct_begin, !seqA.
  rewrite AA at 2.
  arewrite (sb^? ⨾ (sb^? ⨾ rmw_dep ⨾ sb^?)＊ ⨾ sb^? ⊆ sb^?).
  { rewrite WF.(rmw_dep_in_sb). generalize (@sb_trans G). ins. relsf. }
  arewrite (rmw_dep ⨾ sb^? ⨾ ⦗W⦘ ⊆ rmw_dep ⨾ sb ⨾ ⦗W⦘).
  { rewrite (dom_r WF.(wf_rmw_depD)) at 1. rewrite R_ex_in_R. type_solver. }
  sin_rewrite DEPS_RMW_SB.
  arewrite (ctrl ⊆ data ∪ ctrl ∪ addr ⨾ sb^? ∪ rfi) at 2.
  seq_rewrite <- ct_end.
  apply ppo_in_dob_helper; auto.
Qed.

Lemma s_ppo_in_ord : s_ppo ⊆ (obs'⁺ ∩ sb ∪ dob ∪ aob ∪ boba' ∪ sb ⨾ ⦗F^ld⦘)⁺.
Proof.
  rewrite s_ppo_in_dob. apply clos_trans_mori. eauto with hahn. 
Qed.

Lemma s_ar_int_in_ord : ⦗R⦘ ⨾ s_ar_int⁺ ⨾ ⦗W⦘ ⊆ (obs' ∪ dob ∪ aob ∪ boba')⁺.
Proof.
  unfold imm_s_ppo.ar_int.
  transitivity (⦗R⦘ ⨾  ((obs'⁺∩ sb) ∪ dob ∪ aob ∪ boba' ∪ sb ⨾ ⦗F^ld⦘)⁺ ⨾ ⦗W⦘).
  2: { rewrite path_union.
       relsf; unionL.
       { arewrite_id ⦗R⦘; arewrite_id ⦗W⦘.
         rels.
         arewrite (obs'⁺ ∩ sb ⊆ obs'⁺).
         apply inclusion_t_t2.
         apply_unionL_once.
         apply_unionL_once.
         apply_unionL_once.
         { apply inclusion_t_t. basic_solver. }
         all: rewrite <- ct_step; basic_solver. }
       rewrite (dob_in_sb WF) at 1 2.
       rewrite (aob_in_sb WF) at 1 2.
       rewrite (bob'_in_sb WF) at 1 2.
       arewrite (obs'⁺ ∩ sb ⊆ sb).
       rewrite ct_begin.
       arewrite_id ⦗F^ld⦘ at 2.
       generalize (@sb_trans G); ins; relsf.
       arewrite (⦗F^ld⦘ ⨾ sb^? ⨾ ⦗W⦘ ⊆ ⦗F^ld⦘ ⨾ sb) by type_solver.
       unfold Arm.bob', Arm.bob.
       rewrite <- ct_step. basic_solver 21. }
  arewrite (detour ⊆ detour ∩ sb).
  rewrite W_ex_acq_sb_in_boba1, bob_in_boba, detour_in_obs; auto.
  hahn_frame.
  apply inclusion_t_t2.
  apply_unionL_once.
  2: { rewrite <- ct_step. unfold Arm.aob. basic_solver 12. }
  apply_unionL_once.
  2: { apply inclusion_t_t; basic_solver 12. }
  apply_unionL_once.
  2: by unfolder; ins; econs; eauto.
  apply_unionL_once.
  { rewrite <- ct_step; rewrite <- ct_step; unfold Arm.obs'; ie_unfolder; basic_solver 12. }
  apply s_ppo_in_ord.
Qed.

Lemma C_EXT_helper: imm_s.acyc_ext G (⦗F∩₁Sc⦘ ⨾ s_hb ⨾ eco ⨾ s_hb ⨾ ⦗F∩₁Sc⦘).
Proof.
apply (acyc_ext_helper WF).
rewrite s_ar_int_in_ord. psc_in_ord.
arewrite (rfe ⊆ (obs' ∪ dob ∪ aob ∪ boba')⁺ ).
unfold Arm.obs'; rewrite <- ct_step; basic_solver 12.
relsf; red; relsf.
apply (external_alt2 WF CON rmw_sb_in_ctrl).
Qed.

Lemma C_SC: acyclic (psc_f ∪ psc_base).
Proof.
  rewrite psc_base_in_ord, psc_f_in_ord.
  rewrite unionK.
  red. rewrite ct_of_ct.
  apply (external_alt2 WF CON rmw_sb_in_ctrl).
Qed.

Lemma IMM_consistent : imm_consistent G.
Proof.
cdes CON.
red; splits; eauto.
apply COH.
apply C_EXT.
apply C_SC.
Qed.

End immToARM.
