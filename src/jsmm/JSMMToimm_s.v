(******************************************************************************)
(** * JSMM is weaker than IMM_S   *)
(******************************************************************************)

Require Import Classical Peano_dec.
From hahn Require Import Hahn.

Require Import Events.
Require Import Execution.
Require Import Execution_eco.
Require Import imm_bob imm_s_ppo.
Require Import imm_s_hb.
Require Import imm_s.
Require Import JSMM.

Set Implicit Arguments.
Remove Hints plus_n_O.

Section JSMM_TO_IMM_S.

Variable G : execution.
Hypothesis WF : Wf G.

Notation "'E'" := G.(acts_set).
Notation "'sb'" := G.(sb).
Notation "'rf'" := G.(rf).
Notation "'co'" := G.(co).
Notation "'rmw'" := G.(rmw).
Notation "'data'" := G.(data).
Notation "'addr'" := G.(addr).
Notation "'ctrl'" := G.(ctrl).
Notation "'rmw_dep'" := G.(rmw_dep).

Notation "'fr'" := G.(fr).
Notation "'eco'" := G.(eco).
Notation "'coe'" := G.(coe).
Notation "'coi'" := G.(coi).
Notation "'deps'" := G.(deps).
Notation "'rfi'" := G.(rfi).
Notation "'rfe'" := G.(rfe).

Notation "'rs'" := G.(rs).
Notation "'release'" := G.(release).
Notation "'sw'" := G.(imm_s_hb.sw).
Notation "'hb'" := G.(imm_s_hb.hb).

Notation "'sw_js'" := G.(JSMM.sw).
Notation "'hb_js'" := G.(JSMM.hb).

Notation "'detour'" := G.(detour).

Notation "'ar_int'" := G.(ar_int).
Notation "'ppo'" := G.(ppo).
Notation "'bob'" := G.(bob).

Notation "'ar'" := G.(ar).

Notation "'lab'" := G.(lab).
Notation "'loc'" := (loc lab).
Notation "'val'" := (val lab).
Notation "'mod'" := (mod lab).
Notation "'same_loc'" := (same_loc lab).

Notation "'R'" := (fun a => is_true (is_r lab a)).
Notation "'W'" := (fun a => is_true (is_w lab a)).
Notation "'F'" := (fun a => is_true (is_f lab a)).
Notation "'Rlx'" := (fun a => is_true (is_rlx lab a)).
Notation "'Acq'" := (fun a => is_true (is_acq lab a)).
Notation "'Rel'" := (fun a => is_true (is_rel lab a)).
Notation "'Acq/Rel'" := (fun a => is_true (is_ra lab a)).
Notation "'Sc'" := (fun a => is_true (is_sc lab a)).

Lemma sw_js_in_sw : sw_js ⊆ sw.
Proof using WF.
  unfold imm_s_hb.sw, JSMM.sw.
  arewrite (Sc ⊆₁ Rel) at 1 by mode_solver.
  arewrite (Sc ⊆₁ Acq) by mode_solver.
  unfold imm_s_hb.release, imm_s_hb.rs.
  rewrite !seqA.
  assert (⦗fun _ => True⦘ ⊆ (rf ⨾ rmw)＊) as HH
      by basic_solver.
  rewrite <- HH.
  rewrite <- !inclusion_id_cr.
  rewrite !seq_id_l.
  rewrite (dom_l WF.(wf_rfD)) at 1.
  basic_solver 10.
Qed.

Lemma hb_js_in_hb : hb_js ⊆ hb.
Proof using WF. unfold imm_s_hb.hb, JSMM.hb. by rewrite sw_js_in_sw. Qed.

Lemma hb_jsE : hb_js ≡ ⦗E⦘ ⨾ hb_js ⨾ ⦗E⦘.
Proof using WF.
  apply dom_helper_3. rewrite hb_js_in_hb.
  apply dom_helper_3. by apply wf_hbE.
Qed.

Lemma sw_js_sc : sw_js ≡ ⦗Sc⦘ ⨾ sw_js ⨾ ⦗Sc⦘.
Proof using. apply dom_helper_3. unfold JSMM.sw. basic_solver. Qed.

Lemma sc_hb_js_sc_in_sc_ct :
  ⦗Sc⦘ ⨾ hb_js ⨾ ⦗Sc⦘ ⊆
  (⦗Sc⦘ ⨾ sb ⨾ ⦗Sc⦘ ∪ ⦗Sc⦘ ⨾ rf ⨾ ⦗Sc⦘)⁺.
Proof using.
  unfold JSMM.hb, JSMM.sw.
  rewrite path_tur with (adom:=Sc) (bdom:=Sc).
  3,4: basic_solver.
  2: by apply sb_trans.
  rewrite !seq_union_l, !seq_union_r.
  unionL.
  { rewrite <- ct_step. by unionR left. }
  rewrite !seqA.
  arewrite ((⦗Sc⦘ ⨾ sb)^? ⨾ ⦗Sc⦘ ⊆ ⦗Sc⦘ ⨾ (⦗Sc⦘ ⨾ sb)^? ⨾ ⦗Sc⦘).
  { basic_solver 10. }
  arewrite (⦗Sc⦘ ⨾ (sb ⨾ ⦗Sc⦘ ∪ ⦗Sc⦘ ⨾ rf ⨾ ⦗Sc⦘)⁺ ⨾ ⦗Sc⦘ ⊆
            (⦗Sc⦘ ⨾ sb ⨾ ⦗Sc⦘ ∪ ⦗Sc⦘ ⨾ rf ⨾ ⦗Sc⦘)⁺).
  2: { rewrite crE.
       rewrite !seq_union_l, !seq_union_r, seq_id_l, !seqA.
       unionL.
       { basic_solver. }
       arewrite 
       (⦗Sc⦘ ⨾ sb ⨾ ⦗Sc⦘ ⊆
             (⦗Sc⦘ ⨾ sb ⨾ ⦗Sc⦘ ∪ ⦗Sc⦘ ⨾ rf ⨾ ⦗Sc⦘)⁺) at 2.
       apply ct_ct. }
  arewrite (⦗Sc⦘ ⨾ (sb ⨾ ⦗Sc⦘ ∪ ⦗Sc⦘ ⨾ rf ⨾ ⦗Sc⦘)⁺ ⨾ ⦗Sc⦘ ⊆
            ⦗Sc⦘ ⨾ (sb ⨾ ⦗Sc⦘ ∪ ⦗Sc⦘ ⨾ rf ⨾ ⦗Sc⦘)⁺).
  (* TODO: generalize the next code to a lemma about
           the transitive closure! *)
  red. intros x y HH.
  apply seq_eqv_l in HH. destruct HH as [SCX HH].
  induction HH.
  { apply ct_step. generalize SCX H.
    basic_solver 10. }
  apply ct_ct. exists y. split; auto.
  apply IHHH2.
  clear -HH1.
  assert (((sb ⨾ ⦗Sc⦘ ∪ ⦗Sc⦘ ⨾ rf ⨾ ⦗Sc⦘)⁺ ⨾ ⦗Sc⦘) x y) as AA.
  2: { apply seq_eqv_r in AA. desf. }
  assert ((sb ⨾ ⦗Sc⦘ ∪ ⦗Sc⦘ ⨾ rf ⨾ ⦗Sc⦘)⁺ ⊆
          (sb ⨾ ⦗Sc⦘ ∪ ⦗Sc⦘ ⨾ rf ⨾ ⦗Sc⦘)⁺ ⨾ ⦗Sc⦘ ) as BB.
  2: by apply BB.
  arewrite (sb ⨾ ⦗Sc⦘ ∪ ⦗Sc⦘ ⨾ rf ⨾ ⦗Sc⦘ ⊆
            (sb ⨾ ⦗Sc⦘ ∪ ⦗Sc⦘ ⨾ rf ⨾ ⦗Sc⦘) ⨾ ⦗Sc⦘).
  { basic_solver. }
  apply inclusion_ct_seq_eqv_r.
Qed.

Lemma hb_js_co_fr_ac sc (IPC : imm_s.imm_psc_consistent G sc) :
  acyclic (hb_js ∪ ⦗ Sc ⦘ ⨾ (fr ∪ co) ⨾ ⦗ Sc ⦘).
Proof using WF.
  cdes IPC. cdes IC.
  assert (acyclic hb_js) as HBJSAC.
  { rewrite hb_js_in_hb.
    red. unfold imm_s_hb.hb. rewrite ct_of_ct.
    apply hb_irr; auto. }
  apply acyclic_ud with (adom:=Sc) (bdom:=Sc); auto.
  1,2: basic_solver.
  arewrite (hb_js⁺ ⊆ hb_js).
  rewrite sc_hb_js_sc_in_sc_ct.
  arewrite (⦗Sc⦘ ⨾ sb ⨾ ⦗Sc⦘ ⊆ psc_base G).
  { unfold psc_base, scb. basic_solver 40. }
  arewrite (⦗Sc⦘ ⨾ rf ⨾ ⦗Sc⦘ ⊆ psc_base G).
  { unfold psc_base, scb.
    arewrite (⦗Sc⦘ ⨾ rf ⨾ ⦗Sc⦘ ⊆
                   ⦗Sc⦘ ⨾ (⦗Sc⦘ ⨾ rf ⨾ ⦗Sc⦘) ⨾ ⦗Sc⦘).
    { basic_solver. }
    hahn_frame.
    arewrite (⦗Sc⦘ ⨾ rf ⨾ ⦗Sc⦘ ⊆ hb ∩ same_loc).
    2: basic_solver 20.
    apply inclusion_inter_r.
    2: rewrite wf_rfl; auto; basic_solver.
    rewrite <- hb_js_in_hb.
    unfold JSMM.hb.
    rewrite <- ct_step. by right. }
  arewrite (⦗Sc⦘ ⨾ (fr ∪ co) ⨾ ⦗Sc⦘ ⊆ psc_base G).
  { unfold psc_base, scb. basic_solver 40. }
  rewrite unionK.
  arewrite ((psc_base G)⁺ ∪ psc_base G ⊆ (psc_base G)⁺).
  red. rewrite ct_of_ct.
  eapply inclusion_acyclic.
  2: by apply Cpsc.
  done.
Qed.

Theorem s_imm_consistent_implies_jsmm_consistent sc
      (IPC : imm_s.imm_psc_consistent G sc) :
  exists tot, jsmm_consistent G tot.
Proof using WF.
  cdes IPC. cdes IC.
  exists (⦗E⦘ ⨾
            tot_ext (acts G)
            (hb_js ∪ ⦗ Sc ⦘ ⨾ (fr ∪ co) ⨾ ⦗ Sc ⦘) ⨾
          ⦗E⦘).
  red. splits.
  { red. split; [split|].
    { rewrite <- restr_relE.
      apply irreflexive_restr.
      apply tot_ext_irr.
      eapply hb_js_co_fr_ac; eauto. }
    { rewrite <- restr_relE.
      apply transitive_restr.
      apply tot_ext_trans. }
    red. ins.
    edestruct tot_ext_total.
    3: by eauto.
    all: eauto.
    { left.
      apply seq_eqv_l. split; auto.
      apply seq_eqv_r. split; eauto. }
    right.
    apply seq_eqv_l. split; auto.
    apply seq_eqv_r. split; eauto. }
  { rewrite <- tot_ext_extends.
    rewrite hb_jsE at 1.
    hahn_frame. eauto with hahn. }
  { rewrite hb_js_in_hb, rf_in_eco.
    arewrite (eco ⊆ eco^?). apply IPC. }
  { unfolder. intros w' [r [HBWR HH]].
    destruct HH as [w [RF [[HBJS AA] WW']]].
    assert (hb w w') as HB by (by apply hb_js_in_hb).
    apply WF.(wf_hbE) in HB.
    apply seq_eqv_l in HB. destruct HB as [EW HB].
    apply seq_eqv_r in HB. destruct HB as [HB EW'].
    apply (dom_l WF.(wf_rfD)) in RF.
    apply seq_eqv_l in RF. destruct RF as [WW RF].
    edestruct is_w_loc as [l LL].
    { apply WW. }
    assert (w <> w') as NEQ.
    { intros HH. subst.
      eapply hb_irr; eauto. }
    edestruct WF.(wf_co_total).
    3: by eauto.
    1,2: by unfolder; splits.
    { eapply Cint. exists r. split.
      { apply hb_js_in_hb. eauto. }
      right. apply fr_in_eco. eexists. eauto. }
    eapply Cint. exists w'. split; eauto.
    right. by apply co_in_eco. }
  { intros w' HH.
    apply seq_eqv_l in HH. destruct HH as [[WW' SCW'] HH].
    destruct HH as [r [TOT HH]].
    apply seq_eqv_l in HH. destruct HH as [[RR SCR] HH].
    destruct HH as [w [RF HH]].
    apply seq_eqv_l in HH. destruct HH as [[WW SCW] [TOTJS SL]].
    apply seq_eqv_l in TOTJS. destruct TOTJS as [EW' TOTJS].
    apply seq_eqv_r in TOTJS. destruct TOTJS as [TOTJS EW].
    edestruct is_w_loc as [l LL].
    { apply WW. }
    assert (w <> w') as NEQ.
    { intros HH. subst.
      eapply tot_ext_irr; [|by eauto].
      eapply hb_js_co_fr_ac; eauto. }
    edestruct WF.(wf_co_total).
    3: by eauto.
    1,2: by unfolder; splits.
    all: eapply tot_ext_irr;
         [by eapply hb_js_co_fr_ac; eauto|].
    { eapply tot_ext_trans.
      { generalize TOT. basic_solver. }
      apply tot_ext_extends.
      right.
      apply seq_eqv_l. split; [by apply SCR|].
      apply seq_eqv_r. split; [|by apply SCW'].
      left.
      eexists. eauto. }
    eapply tot_ext_trans; eauto.
    apply tot_ext_extends.
    right.
    apply seq_eqv_l. split; auto.
    apply seq_eqv_r. split; auto.
      by right. }
  { intros w' HH.
    apply seq_eqv_l in HH. destruct HH as [[WW' SCW'] HH].
    destruct HH as [r [HBWR' HH]].
    destruct HH as [w [[HBWR RF] HH]].
    apply seq_eqv_l in HH. destruct HH as [[WW SCW] [TOTJS SL]].
    apply seq_eqv_l in TOTJS. destruct TOTJS as [EW' TOTJS].
    apply seq_eqv_r in TOTJS. destruct TOTJS as [TOTJS EW].
    edestruct is_w_loc as [l LL].
    { apply WW. }
    assert (w <> w') as NEQ.
    { intros HH. subst.
      eapply tot_ext_irr; [|by eauto].
      eapply hb_js_co_fr_ac; eauto. }
    edestruct WF.(wf_co_total).
    3: by eauto.
    1,2: by unfolder; splits.
    { eapply Cint.
      eexists. split.
      { apply hb_js_in_hb. apply HBWR'. }
      right. apply fr_in_eco.
      eexists. eauto. }
    eapply tot_ext_irr; [by eapply hb_js_co_fr_ac; eauto|].
    eapply tot_ext_trans; eauto.
    apply tot_ext_extends.
    right.
    apply seq_eqv_l. split; auto.
    apply seq_eqv_r. split; auto.
      by right. }
  intros w' HH.
  apply seq_eqv_l in HH. destruct HH as [[WW' SCW'] HH].
  destruct HH as [r [TOT HH]].
  apply seq_eqv_l in TOT. destruct TOT as [EW' TOT].
  apply seq_eqv_r in TOT. destruct TOT as [TOT ER].
  apply seq_eqv_l in HH. destruct HH as [[RR SCR] HH].
  destruct HH as [w [[HBWR RF] [HBJS SL]]].
  apply (dom_l WF.(wf_rfD)) in RF.
  apply seq_eqv_l in RF. destruct RF as [WW RF].
  apply (dom_l WF.(wf_rfE)) in RF.
  apply seq_eqv_l in RF. destruct RF as [EW RF].
  edestruct is_w_loc as [l LL].
  { apply WW. }
  assert (w <> w') as NEQ.
  { intros HH. subst.
    eapply hb_irr; eauto.
    apply hb_js_in_hb. eauto. }
  edestruct WF.(wf_co_total).
  3: by eauto.
  1,2: by unfolder; splits.
  { eapply tot_ext_irr; [by eapply hb_js_co_fr_ac; eauto|].
    eapply tot_ext_trans.
    { generalize TOT. basic_solver. }
    apply tot_ext_extends.
    right.
    apply seq_eqv_l. split; [by apply SCR|].
    apply seq_eqv_r. split; [|by apply SCW'].
    left.
    eexists. eauto. }
  eapply Cint.
  eexists.
  split.
  { apply hb_js_in_hb. apply HBJS. }
  right. by apply co_in_eco.
Qed.

End JSMM_TO_IMM_S.
