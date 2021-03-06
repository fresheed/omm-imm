(******************************************************************************)
(** Conversions between single steps and block execution steps                *)
(******************************************************************************)
Require Import Classical Peano_dec.
From hahn Require Import Hahn.
Require Import Omega.
Require Import Events.
Require Import Execution.
Require Import Execution_eco.
Require Import imm_s_hb.
Require Import imm_s.
Require Import OCaml.
Require Import OmmProgram.
Require Import ListHelpers.
Require Import OmmImmCompScheme. 
Require Import ListHelpersTemp.
Require Import Utils.
Require Import ClosuresProperties. 
Require Import Prog.
Require Import ProgToExecution.
Require Import ProgToExecutionProperties.
Require Import Logic.Decidable. 
From PromisingLib Require Import Basic Loc.
Require Import Basics. 
Set Implicit Arguments.

Section Steps.

Lemma init_mm_same: forall PO BPI (COMP: is_thread_block_compiled PO BPI),
    mm_similar_states (init PO) (binit BPI).
Proof.
  ins. red. simpl. splits; auto.
  3: { basic_solver. }
  2: { ins. simpl. unfold DepsFile.init. simpl. basic_solver. }
  unfold init_execution. red. simpl. basic_solver. 
Qed.

Lemma steps_same_instrs sti sti' (STEPS: exists tid, (step tid)＊ sti sti'):
  instrs sti = instrs sti'.
Proof.
  destruct STEPS as [tid STEPS]. apply crt_num_steps in STEPS.
  destruct STEPS as [n STEPS].
  generalize dependent sti'.
  induction n.
  - intros sti' STEPS. simpl in STEPS. generalize STEPS. basic_solver 10.
  - intros sti' STEPS.
    rewrite step_prev in STEPS. destruct STEPS as [sti'' STEPS'']. desc.
    replace (instrs sti) with (instrs sti'').
    { red in STEPS''0. desf. red in STEPS''0. desf. }
    symmetry. eapply IHn. eauto.
Qed.

Lemma omm_steps_same_instrs sto sto' (STEPS: exists tid, (Ostep tid)＊ sto sto'):
  instrs sto = instrs sto'.
Proof.
  (* TODO: join with previous*)
  destruct STEPS as [tid STEPS]. apply crt_num_steps in STEPS.
  destruct STEPS as [n STEPS].
  generalize dependent sto'.
  induction n.
  - intros sto' STEPS. simpl in STEPS. generalize STEPS. basic_solver 10.
  - intros sto' STEPS.
    rewrite step_prev in STEPS. destruct STEPS as [sto'' STEPS'']. desc.
    replace (instrs sto) with (instrs sto'').
    { red in STEPS''0. desf. red in STEPS''0. desf. }
    symmetry. eapply IHn. eauto.
Qed.

Definition on_block st block :=
  ⟪ PROG_BLOCK: block = sublist (instrs st) (pc st) (length block) ⟫ /\
  ⟪ COMP_BLOCK: (exists oinstr, is_instruction_compiled oinstr block) ⟫.

Definition at_compilation_block st :=
  (exists block, on_block st block) \/ is_terminal st.

Definition oseq_step (tid : thread_id) sti1 sti2 :=
  exists block, on_block sti1 block /\
           (step tid) ^^ (length block) sti1 sti2. 

Lemma igt_compiled_addr cond addr PO PI (IN_COMP: In (Instr.ifgoto cond addr) PI)
      (COMP: is_thread_compiled PO PI):
  addr <= length PI.
Proof.
  cdes COMP. cdes COMP0.
  red in COMP1. desc. clear COMP COMP0. subst PI. 
  replace (length (flatten BPI)) with (length (flatten BPI0)). 
  2: { ins.
       rewrite <- firstn_all with (l := BPI0).
       rewrite <- firstn_all with (l := BPI).
       replace (length BPI) with (length BPI0).
       2: { eapply Forall2_length; eauto. }
       apply SAME_STRUCT_PREF. eapply correction_same_struct; eauto. }
  assert (exists BPI_corr, Forall2 (block_corrected BPI_corr) BPI0 BPI /\ same_struct BPI_corr BPI0) as CORR_ALT. 
  { exists BPI0. splits; vauto. apply same_struct_refl. }
  desc.
  replace (length (flatten BPI0)) with (length (flatten BPI_corr)). 
  2: { ins.
       rewrite <- firstn_all with (l := BPI0).
       rewrite <- firstn_all with (l := BPI_corr).
       replace (length BPI_corr) with (length BPI0).
       2: { symmetry. red in CORR_ALT0. eapply Forall2_length; eauto. }
       apply SAME_STRUCT_PREF. auto. }
  clear COMP3 CORR_ALT0. 
  generalize dependent BPI. generalize dependent BPI0. induction PO.
  { ins. inversion COMP1. subst. inversion CORR_ALT. subst. vauto. }
  ins. inversion COMP1. subst. inversion CORR_ALT. subst.
  simpl in IN_COMP. apply in_app_or in IN_COMP. des.
  2: { specialize (IHPO l' H3 l'0 IN_COMP H5). auto. }
  (* Ltac invert_nil := match goal with *)
  (*                    | H:  *)
  inversion H1; subst. 
  { inversion H2. subst. inversion H7. subst. inversion H4. subst.
    subst ld. simpl in IN_COMP. des; vauto. }
  { subst. inversion H2. subst. inversion H7. subst. inversion H9. subst.
    inversion H6. subst. inversion H4. subst.  
    subst f st. simpl in IN_COMP. des; vauto. }
  { subst. inversion H2. subst. inversion H7. subst. inversion H9. subst.
    inversion H6. subst. inversion H4. subst.  
    subst f ld. simpl in IN_COMP. des; vauto. }
  { subst. inversion H2. subst. inversion H7. subst. inversion H9. subst.
    inversion H6. subst. inversion H4. subst.  
    subst f exc. simpl in IN_COMP. des; vauto. }
  { subst. inversion H2. subst. inversion H7. subst. inversion H4. subst.
    subst asn. simpl in IN_COMP. des; vauto. }
  subst. inversion H2. subst. inversion H7. subst.
  subst igt. inversion H4; vauto. 
  simpl in IN_COMP. des; [| done].
  inversion IN_COMP. subst.
  subst addr1.
  rewrite <- firstn_skipn with (l := BPI_corr) (n := n) at 2.
  rewrite flatten_app, app_length. omega.
Qed. 

Lemma is_terminal_pc_bounded st tid PO PI (REACH: (step tid)＊ (init PI) st)
      (COMP: is_thread_compiled PO PI):
  is_terminal st <-> pc st = length (instrs st).
Proof.
  unfold is_terminal. 
  split; [|omega]. 
  apply crt_num_steps in REACH. desc. generalize dependent st. induction n.
  { ins. red in REACH. desc. subst. simpl in *. omega. }
  ins. red in REACH. desc.
  do 2 (red in REACH0; desc).
  assert (forall instr, Some instr = nth_error (instrs z) (pc z) ->
                   pc st = pc z + 1 -> pc st = length (instrs st)) as NEXT_HELPER. 
  { ins. assert (pc z < length (instrs st)).
    { apply nth_error_Some, OPT_VAL. rewrite <- INSTRS. eauto. }
    omega. }
  inversion ISTEP0; try (by eapply NEXT_HELPER; eauto).
  destruct (Const.eq_dec (RegFile.eval_expr (regf z) expr) 0).
  { eapply NEXT_HELPER; eauto. }
  forward eapply (@igt_compiled_addr expr shift PO (instrs z)) as BOUND.
  { subst instr. eapply nth_error_In. eauto. }
  { replace (instrs z) with PI; auto.
    replace PI with (instrs (init PI)) by vauto.
    apply steps_same_instrs. exists tid. apply crt_num_steps. eauto. }
  rewrite INSTRS in BOUND. omega.
Qed. 

Definition bst_from_st st BPI b :=
  {|
    binstrs := BPI;
    bpc := b;
    bG := G st; 
    beindex := eindex st;
    bregf := regf st;
    bdepf := depf st;
    bectrl := ectrl st |}. 

Definition min_prop {A: Type} (P: list A -> Prop)
  := forall l (Pl: P l), (forall l1 l2 (LT: l2 <> []) (SPLIT: l = l1 ++ l2), ~ P l1). 

Lemma firstn_length_leq {A: Type} (l: list A) i:
  length (firstn i l) <= length l.
Proof.
  generalize dependent l. induction i.
  { ins. omega. }
  ins. destruct l; vauto.
  simpl. apply le_n_S. auto.
Qed. 


Lemma start_block_deterministic
      (A : Type)
      (P : list A -> Prop)
      (block : list A)
      (block' : list A)
      (ll : list (list A))
      (MINPROP : min_prop P)
      (NEblock: block <> [])
      (Pblock: P block)
      (NE_B : block' <> [])
      (BLOCK'_P : P block')
      (BLOCK' : block' = firstn (length block') (flatten (block :: ll))):
  block' = block.
Proof.
  assert (block = firstn (length block) (block ++ flatten ll)) as L0. 
  { rewrite <- Nat.add_0_r with (n := length block).
    rewrite firstn_app_2. simpl. symmetry. apply app_nil_r. }
  assert (length block' <= length (flatten (block :: ll))) as LEN_B.
  { apply (@f_equal _ _ (@length _)) in BLOCK'.
    pose proof (firstn_length_leq (flatten (block :: ll)) (length block')). omega. }
  assert (length block <= length (flatten (block :: ll))) as LEN_L0. 
  { simpl. rewrite app_length. omega. }
  destruct (lt_eq_lt_dec (length block') (length block)) as [[LT | EQ] | GT].
  2: { forward eapply (@firstn_ge_incl _ (flatten (block :: ll)) (length block') (length block)) as PREF; [omega| ].
       rewrite EQ in PREF at 2. rewrite skipn_firstn_nil in PREF.
       rewrite app_nil_r in PREF. simpl in BLOCK'. congruence. }
  { forward eapply (@firstn_ge_incl _ (flatten (block :: ll)) (length block') (length block)) as PREF; [omega| ].
    exfalso.
    simpl in *. rewrite <- BLOCK', <- L0 in PREF.
    red in MINPROP. specialize (MINPROP block Pblock block' (skipn (length block') block)).
    apply MINPROP; vauto.
    apply (@f_equal _ _ (@length _)) in PREF. rewrite app_length in PREF.
    red. ins. apply NE_B. apply length_zero_iff_nil.
    apply length_zero_iff_nil in H. omega. }
  forward eapply (@firstn_ge_incl _ (flatten (block :: ll)) (length block) (length block')) as PREF; [omega| ].
  exfalso. 
  simpl in *. rewrite <- BLOCK', <- L0 in PREF.
  red in MINPROP. specialize (MINPROP block' BLOCK'_P block (skipn (length block) block')).
  apply MINPROP; vauto.
  apply (@f_equal _ _ (@length _)) in PREF. rewrite app_length in PREF.
  red. ins. apply NEblock.
  apply length_zero_iff_nil.  apply length_zero_iff_nil in H. omega. 
Qed. 

Lemma ll_l_corr {A: Type} ll (l: list A) (FLT: l = flatten ll) block b
      (NE_LL: Forall (fun l => l <> []) ll)
      P (MINPROP: min_prop P)
      (P_LL: Forall P ll)
      (NE_B: block <> [])
      (BLOCK_P: P block):
  block = sublist l (length (flatten (firstn b ll))) (length block)
  <-> Some block = nth_error ll b.
Proof.
  generalize dependent block. generalize dependent ll. generalize dependent l. 
  induction b.
  { intros. unfold sublist. rewrite FLT. simpl.
    split.
    { intros BLOCK. destruct ll.
      { simpl in BLOCK. rewrite firstn_nil in BLOCK. vauto. }
      f_equal.
      eapply start_block_deterministic; eauto; [inv NE_LL| inv P_LL]. }
    intros BLOCK. destruct ll; vauto. simpl.
    rewrite <- Nat.add_0_r with (n := length l0). rewrite firstn_app_2.
    simpl. symmetry. apply app_nil_r. } 
  ins. destruct ll; vauto.
  { simpl. unfold sublist. simpl. rewrite firstn_nil. vauto. }
  simpl. rewrite app_length. unfold sublist.
  rewrite skipn_app.
  replace (skipn (length l0 + length (flatten (firstn b ll))) l0) with (@nil A).
  2: { clear NE_LL. clear P_LL. induction l0.
       { simpl. destruct (length (flatten (firstn b ll))); vauto. }
       simpl. auto. }
  rewrite app_nil_l.
  replace (length l0 + length (flatten (firstn b ll)) - length l0) with (length (flatten (firstn b ll))) by omega.    
  apply IHb; vauto.
  { inversion NE_LL. vauto. }
  inversion P_LL. vauto.
Qed. 

Lemma instr_compiled_min_prop:
  min_prop (fun blk : list Instr.t =>
              exists oinstr : Instr.t, is_instruction_compiled oinstr blk).
Proof.
  red. intros block [oinstr COMP] block' block'' NE'' BLOCK_STRUCT.
  red. intros [oinstr' COMP'].
  inversion COMP; subst.
  all: (inversion COMP'; subst; inversion H0; subst; auto).
Qed. 

Lemma ll_l_corr_helper BPI PI (FLT: PI = flatten BPI) block b
      (COMP: exists PO, is_thread_block_compiled PO BPI)
      (COMP_BLOCK: exists oinstr, is_instruction_compiled oinstr block)
  :
    block = sublist PI (length (flatten (firstn b BPI))) (length block)
    <-> Some block = nth_error BPI b.
Proof.
  eapply ll_l_corr with (P := fun blk => exists oinstr, is_instruction_compiled oinstr blk); vauto.
  { desc. eapply COMPILED_NONEMPTY; eauto. }
  { apply instr_compiled_min_prop. }
  { clear COMP_BLOCK. eapply Forall_index. ins.
    desc. eapply resulting_block_compiled; eauto.
    eapply COMPILED_NONEMPTY; eauto. } 
  desc. inversion COMP_BLOCK; vauto.
Qed. 

Lemma st_bst_prog_blocks bst block (COMP: exists PO, is_thread_block_compiled PO (binstrs bst)):
  on_block (bst2st bst) block <-> Some block = nth_error (binstrs bst) (bpc bst).
Proof.
  desc.
  assert (Forall (fun l : list Instr.t => l <> []) (binstrs bst)) as BPI_NE. 
  { eapply COMPILED_NONEMPTY; eauto. }
  split.
  { intros ON_BLOCK. red in ON_BLOCK. desc.
    unfold bst2st in PROG_BLOCK. simpl in PROG_BLOCK.
    eapply ll_l_corr_helper in PROG_BLOCK; eauto. }
  intros BLOCK. red.
  forward eapply resulting_block_compiled as COMP'; eauto. 
  splits; auto. 
  eapply ll_l_corr_helper; vauto.
Qed. 

Definition on_block_pc pc PI block := 
  ⟪BLOCK: block = sublist PI pc (length block)⟫ /\
  ⟪COMP_BLOCK: exists oinstr : Instr.t, is_instruction_compiled oinstr block⟫. 

(* TODO: remove it since exact instruction is known when block_start is called? *)
Lemma block_start pc PI block instr (BLOCK: on_block_pc pc PI block)
      (AT_PC: Some instr = nth_error PI pc):
  (exists mode, instr = Prog.Instr.fence mode) \/
  (exists loc expr, instr = Prog.Instr.load Orlx loc expr) \/
  (exists cond loc, instr = Prog.Instr.ifgoto cond loc) \/
  (exists reg expr, instr = Prog.Instr.assign reg expr).
Proof.
  red in BLOCK. desc.
  inversion COMP_BLOCK.
  all: subst; simpl in *.
  (* TODO: refactor *)
  - assert (AT_PC1: Some ld = nth_error PI pc).
    { apply eq_trans with (y := nth_error [ld] 0); auto.
      rewrite <- (NPeano.Nat.add_0_r pc).
      eapply sublist_items; eauto. }
    rewrite <- AT_PC in AT_PC1. inversion AT_PC1.
    right. left. subst ld. eauto.
  - assert (AT_PC1: Some f = nth_error PI pc).
    { apply eq_trans with (y := nth_error [f; st] 0); auto.
      rewrite <- (NPeano.Nat.add_0_r pc).
      eapply sublist_items; eauto. }
    rewrite <- AT_PC in AT_PC1. inversion AT_PC1.
    left. subst f. eauto.
  - assert (AT_PC1: Some f = nth_error PI pc).
    { apply eq_trans with (y := nth_error [f; ld] 0); auto.
      rewrite <- (NPeano.Nat.add_0_r pc).
      eapply sublist_items; eauto. }
    rewrite <- AT_PC in AT_PC1. inversion AT_PC1.
    left. subst f. eauto.
  - assert (AT_PC1: Some f = nth_error PI pc).
    { apply eq_trans with (y := nth_error [f; exc] 0); auto.
      rewrite <- (NPeano.Nat.add_0_r pc).
      eapply sublist_items; eauto. }
    rewrite <- AT_PC in AT_PC1. inversion AT_PC1.
    left. subst f. eauto.
  - assert (AT_PC1: Some asn = nth_error PI pc).
    { apply eq_trans with (y := nth_error [asn] 0); auto.
      rewrite <- (NPeano.Nat.add_0_r pc).
      eapply sublist_items; eauto. }
    rewrite <- AT_PC in AT_PC1. inversion AT_PC1.
    do 3 right. subst asn. eauto.
  - assert (AT_PC1: Some igt = nth_error PI pc).
    { apply eq_trans with (y := nth_error [igt] 0); auto.
      rewrite <- (NPeano.Nat.add_0_r pc).
      eapply sublist_items; eauto. }
    rewrite <- AT_PC in AT_PC1. inversion AT_PC1.
    do 2 right. left. subst igt. eauto.
Qed.


Lemma block_mid pc PI block instr (BLOCK: on_block_pc pc PI block)
      (BLOCK_LEN: length block >= 2)
      (AT_PC1: Some instr = nth_error PI (pc + 1)):
  (exists loc expr, instr = Prog.Instr.store Orlx loc expr) \/
  (exists loc expr, instr = Prog.Instr.load Osc loc expr) \/
  (exists expr loc, instr = Prog.Instr.update (Prog.Instr.exchange expr) false Xpln Osc Osc exchange_reg loc).
Proof.
  red in BLOCK. desc.
  inversion COMP_BLOCK.
  all: (rename H into OINSTR; rename H0 into BLOCK_CONTENTS).
  all: subst block; simpl in *.
  (* trivial cases for single instruction blocks *)
  all: try omega.
  (* now only 2-blocks remain*)
  (* TODO: refactor *)
  { assert (AT_PC1': Some st = nth_error PI (pc + 1)).
    { apply eq_trans with (y := nth_error [f; st] 1); auto.
      eapply sublist_items; eauto. }
    replace instr with st; [| congruence].
    subst st. eauto. }
  { assert (AT_PC1': Some ld = nth_error PI (pc + 1)).
    { apply eq_trans with (y := nth_error [f; ld] 1); auto.
      eapply sublist_items; eauto. }
    replace instr with ld; [| congruence].
    subst ld. eauto. }
  { assert (AT_PC1': Some exc = nth_error PI (pc + 1)).
    { apply eq_trans with (y := nth_error [f; exc] 1); auto.
      eapply sublist_items; eauto. }
    replace instr with exc; [| congruence].
    subst exc. eauto. }
Qed.

Lemma no_acb_between_pc pc1 pc2 n (PC2: pc2 = pc1 + n)
      block (* (BLOCK: on_block st1 block) *)
      PI (BLOCK: on_block_pc pc1 PI block)
      (LT: n < length block) (NZ: n <> 0):
  not ((exists block', on_block_pc pc2 PI block') \/ pc2 >= length PI).
Proof.
  pose proof BLOCK as BLOCK1.
  red in BLOCK. desc.
  inversion COMP_BLOCK.
  all: rename H into OINSTR.
  all: rename H0 into BLOCK_CONTENTS.
  all: subst block; simpl in *.
  (* trivial cases for single instruction blocks *)
  all: try (replace (n) with (0) in *; [vauto | omega]).
  (* now only 2-blocks remain*)
  all: replace n with 1 in *; [| omega].
  (* TODO: refactor *)
  { assert (AT_PC1: Some st = nth_error PI (pc1 + 1)).
    { apply eq_trans with (y := nth_error [f; st] 1); auto.
      eapply sublist_items; eauto. }
    assert (AT_PC: Some f = nth_error PI pc1).
    { apply eq_trans with (y := nth_error [f; st] 0); auto.
      replace pc1 with (pc1 + 0) by omega.
      eapply sublist_items; eauto. }
    
    red. intros ACB2. (* red in ACB2. *)
    destruct ACB2 as [[block2 BLOCK2]| TERM2].
    2: { subst pc2.           
         red in TERM2. (* rewrite NEXT_PC, SAME_INSTRS in TERM2. *)
         pose proof (nth_error_None PI (pc1 + 1)) as CONTRA.
         apply not_iff_compat in CONTRA. destruct CONTRA as [CONTRA _].
         forward eapply CONTRA; [apply OPT_VAL; eauto| ].
         ins. } 
    forward eapply (block_start) as PC1_INSTR; eauto.
    { rewrite PC2. eauto. }
    forward eapply (block_mid BLOCK1) as PC1_INSTR'; eauto.
    des.
    all: (rewrite PC1_INSTR in PC1_INSTR'; discriminate). }
  { assert (AT_PC1: Some ld = nth_error PI (pc1 + 1)).
    { apply eq_trans with (y := nth_error [f; ld] 1); auto.
      eapply sublist_items; eauto. }
    assert (AT_PC: Some f = nth_error PI pc1).
    { apply eq_trans with (y := nth_error [f; ld] 0); auto.
      replace pc1 with (pc1 + 0) by omega.
      eapply sublist_items; eauto. }
    
    red. intros ACB2. 
    destruct ACB2 as [[block2 BLOCK2]| TERM2].
    2: { red in TERM2. (* rewrite NEXT_PC, SAME_INSTRS in TERM2. *)
         pose proof (nth_error_None PI (pc1 + 1)) as CONTRA.
         destruct CONTRA. forward eapply H0; try omega.
         intros. rewrite H1 in AT_PC1. discriminate. }
    forward eapply (block_start) as PC1_INSTR; eauto.
    { rewrite PC2. eauto. }
    forward eapply (block_mid BLOCK1) as PC1_INSTR'; eauto.
    des.
    all: (rewrite PC1_INSTR in PC1_INSTR'; discriminate). }
  { assert (AT_PC1: Some exc = nth_error PI (pc1 + 1)).
    { apply eq_trans with (y := nth_error [f; exc] 1); auto.
      eapply sublist_items; eauto. }
    assert (AT_PC: Some f = nth_error PI pc1).
    { apply eq_trans with (y := nth_error [f; exc] 0); auto.
      replace pc1 with (pc1 + 0) by omega.
      eapply sublist_items; eauto. }      
    red. intros ACB2. 
    destruct ACB2 as [[block2 BLOCK2]| TERM2].
    2: { red in TERM2. rewrite PC2 in TERM2.
         pose proof (nth_error_None PI (pc1 + 1)) as CONTRA.
         destruct CONTRA. forward eapply H0; try omega.
         intros. rewrite H1 in AT_PC1. discriminate. }
    forward eapply (block_start) as PC1_INSTR; eauto.
    { rewrite PC2. eauto. }
    forward eapply (block_mid BLOCK1) as PC1_INSTR'; eauto.
    des.
    all: (rewrite PC1_INSTR in PC1_INSTR'; discriminate). }
Qed. 

Lemma no_acb_between st1 st2 tid block n (STEPS: (step tid) ^^ n st1 st2)
      (BLOCK: on_block st1 block) (LT: n < length block) (NZ: n <> 0):
  not (at_compilation_block st2).
Proof.
  assert (SAME_INSTRS: instrs st2 = instrs st1).
  { symmetry. apply steps_same_instrs. eexists. eapply crt_num_steps. eauto. }
  pose proof BLOCK as BLOCK1.
  red in BLOCK. desc.

  cut (not ((exists block', on_block_pc (pc st2) (instrs st1) block') \/ (pc st2 >= length (instrs st1)))).
  { ins. red. ins. apply H. red in H0. des.
    { left. exists block0. red in H0.
      rewrite SAME_INSTRS in H0. 
      desc. red. splits; eauto. }
    right. red in H0. congruence. }

  eapply no_acb_between_pc; eauto.
  assert (length block = 2 -> exists md, Some (Instr.fence md) = nth_error (instrs st1) (pc st1)).
  { ins. inversion COMP_BLOCK; vauto.
    all: subst f.
    { exists Oacqrel.
      apply eq_trans with (y := nth_error [Instr.fence Oacqrel; st] 0); auto.
      replace (pc st1) with (pc st1 + 0) by omega.
      eapply sublist_items; vauto. }
    { exists Oacq.
      apply eq_trans with (y := nth_error [Instr.fence Oacq; ld] 0); auto.
      replace (pc st1) with (pc st1 + 0) by omega.
      eapply sublist_items; vauto. }
    exists Oacq.
    apply eq_trans with (y := nth_error [Instr.fence Oacq; exc] 0); auto.
    replace (pc st1) with (pc st1 + 0) by omega.
    eapply sublist_items; vauto. }
  inversion COMP_BLOCK; subst; simpl in *; try omega.
  all: replace n with 1 in * by omega.
  all: apply (same_relation_exp (pow_1 (step tid))) in STEPS.
  all: red in STEPS; desc; red in STEPS; desc.
  all: inversion ISTEP0; vauto.
  all: destruct H as [md FENCE]; auto.
  all: rewrite <- FENCE in ISTEP.
  all: inversion ISTEP.
Qed.         

Lemma skipn_0 {A: Type} (l: list A): skipn 0 l = l.
Proof. destruct l; vauto. Qed. 

Lemma on_block_iff_bindex BPI
      block pc (SL: block = sublist (flatten BPI) pc (length block))
      (COMP: exists PO, is_thread_block_compiled PO BPI):
  (exists oinstr, is_instruction_compiled oinstr block) <->
  exists b, Some block = nth_error BPI b /\ pc = length (flatten (firstn b BPI)). 
Proof.
  split.
  2: { ins. desc. eapply resulting_block_compiled; eauto.
       eapply COMPILED_NONEMPTY; eauto. }
  intros COMP_BLOCK.
  assert (COMP': exists PO, itbc_weak PO BPI).
  { desc. exists PO. red. red in COMP. desc. eauto. }
  clear COMP. 
  generalize dependent BPI.
  set (P := fun pc =>   forall BPI : list (list Instr.t),
                block = sublist (flatten BPI) pc (length block) ->
                (exists PO : list Instr.t, itbc_weak PO BPI) ->
                exists b : nat, Some block = nth_error BPI b /\ pc = length (flatten (firstn b BPI))).
  generalize dependent pc. apply (strong_induction P).
  intros pc IH. red. intros BPI BLOCK COMP.
  destruct BPI as [| blk0 BPI']. 
  { exfalso. unfold sublist in BLOCK.
    desc. 
    destruct pc; simpl in BLOCK; rewrite firstn_nil in BLOCK; inversion COMP_BLOCK; vauto. }
  destruct (ge_dec pc (length blk0)) as [GE | LT].
  { assert (block = sublist (flatten BPI') (pc - length blk0) (length block)).
    { rewrite BLOCK at 1.
      simpl. unfold sublist at 1.
      rewrite skipn_app. unfold sublist.
      rewrite firstn_app.
      rewrite skipn_all2; [| omega]. rewrite firstn_nil. simpl.
      rewrite Nat.sub_0_r. auto. }
    forward eapply (IH (pc - length blk0)) as IHprev. 
    { desc. forward eapply COMPILED_NONEMPTY_weak as NE; eauto.
      inversion NE. subst. destruct blk0; vauto. simpl in *. omega. }
    red in IHprev. forward eapply (IHprev BPI' H) as [b' BLOCK']. 
    { desc. destruct PO as [| oinstr_ PO']. 
      { red in COMP. desc. inversion COMP. subst. inversion COMP0. }
      exists PO'. red. red in COMP. destruct COMP as [BPI0 [BPI0' [COMP CORR]]].
      inversion CORR. subst. inversion COMP. subst. eauto. }
    exists (S b'). desc. split; auto. 
    simpl. rewrite app_length. omega. }
  apply not_ge in LT.
  assert (blk0 = firstn (length blk0) (blk0 ++ flatten BPI')) as BLK0.
  { rewrite <- Nat.add_0_r with (n := length blk0). rewrite firstn_app_2.
    rewrite firstn_O. symmetry. apply app_nil_r. }
  destruct (gt_0_eq pc).
  2: { subst. exists 0. simpl in *. split; auto. f_equal.
       unfold sublist in BLOCK. rewrite skipn_0 in BLOCK.
       eapply (start_block_deterministic (P := fun blk => exists oinstr, is_instruction_compiled oinstr blk)); eauto.
       { apply instr_compiled_min_prop. }
       { desc. pose proof (COMPILED_NONEMPTY_weak COMP).
         inv H. }
       { desc.
         eapply resulting_block_compiled_weak; eauto.
         { eapply COMPILED_NONEMPTY_weak; eauto. }
         Unshelve. 2: exact 0. vauto. }
       desc. inversion COMP_BLOCK; vauto. }
  exfalso.
  forward eapply (@no_acb_between_pc 0 pc pc) as NOACB; eauto. 
  { Unshelve. 2: exact (blk0 ++ flatten BPI'). 
    red. splits; vauto.
    desc. eapply resulting_block_compiled_weak; eauto.
    { eapply COMPILED_NONEMPTY_weak; eauto. }
    Unshelve. 2: exact 0. auto. }
  { omega. }
  apply not_or in NOACB. desc.
  apply NOACB. exists block. red. splits; eauto.
Qed. 

Lemma acb_iff_bst st BPI
      (COMP: exists PO, is_thread_compiled_with PO (instrs st) BPI)
      (REACH: exists tid, (step tid)＊ (init (instrs st)) st):
  at_compilation_block st <-> exists bst, ⟪ST: st = bst2st bst⟫ /\
                                   ⟪BINSTRS: binstrs bst = BPI⟫ /\
                                   ⟪BPC: bpc bst <= length BPI⟫. 
Proof.
  split.
  { intros ACB. desc. red in COMP. desc.
    red in ACB. des.
    2: { exists (bst_from_st st BPI (length BPI)). splits; auto. 
         unfold bst2st. simpl. rewrite firstn_all. rewrite <- COMP0.
         forward eapply (@is_terminal_pc_bounded st tid PO (flatten BPI)) as TERM; vauto.
         { congruence. }
         apply TERM in ACB. rewrite <- ACB.
         by destruct st. }
    red in ACB. desc. 
    forward eapply (@on_block_iff_bindex BPI block (pc st)) as [BLOCK_INDEX _]; vauto. 
    { congruence. }
    forward eapply BLOCK_INDEX as [b [BLOCK PC]]; eauto.
    exists (bst_from_st st BPI b). splits; auto.
    2: { apply Nat.lt_le_incl. apply nth_error_Some, OPT_VAL. eauto. } 
    unfold bst2st, bst_from_st. simpl.
    rewrite <- PC, <- COMP0. by destruct st. }
  intros. desc. red. red in COMP. desc.
  subst. 
  destruct (ge_dec (bpc bst) (length (binstrs bst))) as [TERM | NONTERM].
  { right.
    forward eapply (@is_terminal_pc_bounded (bst2st bst) tid PO (instrs (bst2st bst))) as TERM_EQ; vauto.
    apply TERM_EQ. 
    pose proof is_terminal_pc_bounded. 
    simpl.
    rewrite <- firstn_skipn with (n := bpc bst) (l := binstrs bst) at 2.
    rewrite skipn_all2; [| auto]. 
    rewrite app_nil_r. auto. }
  apply not_ge in NONTERM. left.
  apply nth_error_Some, OPT_VAL in NONTERM. destruct NONTERM as [block BLOCK].
  exists block. apply st_bst_prog_blocks; eauto. 
Qed. 

Definition non_igt instr :=
  ~ match instr with | Instr.ifgoto _ _ => True | _ => False end. 

Lemma regular_pc_change st1 st2 tid (STEP: step tid st1 st2)
      instr (AT_PC: Some instr = nth_error (instrs st1) (pc st1))
      (NOT_IGT: non_igt instr):
  pc st2 = pc st1 + 1.
Proof.
  do 2 (red in STEP; desc). red in NOT_IGT. 
  inversion ISTEP0; auto.
  assert (instr = instr0) by congruence. subst. vauto.
Qed. 

Lemma steps_pc_change st1 st2 tid block (ON_BLOCK: on_block st1 block)
      (STEPS: (step tid) ^^ (length block) st1 st2):
  pc st2 = pc st1 + length block \/
  (exists (cond : Instr.expr) (addr : nat),
      block = [Instr.ifgoto cond addr] /\ pc st2 = addr).
Proof.
  red in ON_BLOCK. desc.
  destruct block as [| instr block'].
  { inversion COMP_BLOCK. }
  assert ([instr] = sublist (instrs st1) (pc st1) 1).
  { unfold sublist in *. simpl in PROG_BLOCK.
    simpl. destruct (skipn (pc st1) (instrs st1)); vauto. }
  assert (AT_PC: Some instr = nth_error (instrs st1) (pc st1)).
  { apply eq_trans with (y := nth_error [instr] 0); auto.
    rewrite <- (NPeano.Nat.add_0_r (pc st1)).
    eapply sublist_items; eauto. }
  destruct block' as [| instr' block''].
  { 
    inversion COMP_BLOCK.
    3: { subst. simpl in *.
         apply (same_relation_exp (seq_id_l (step tid))) in STEPS.
         do 2 (red in STEPS; desc).
         (* actually most cases here are nonsense, but they still fit into lemma statement *)
         inversion ISTEP0; auto.
         subst instr.
         destruct (Const.eq_dec (RegFile.eval_expr (regf st1) expr) 0); auto.
         right. exists e. exists n. split; eauto. 
         assert (igt = Instr.ifgoto expr shift) by congruence.
         inversion H0. auto. }    
    all: left; subst; simpl in *.
    all: try apply (same_relation_exp (seq_id_l (step tid))) in STEPS.
    all: eapply regular_pc_change; vauto. }
  left. 
  assert ([instr;  instr'] = sublist (instrs st1) (pc st1) 2).
  { unfold sublist in *. simpl in PROG_BLOCK.
    simpl. destruct (skipn (pc st1) (instrs st1)); vauto.
    destruct l; vauto. }
  assert (AT_PC': Some instr' = nth_error (instrs st1) (pc st1 + 1)).
  { apply eq_trans with (y := nth_error [instr; instr'] 1); auto.
    eapply sublist_items; eauto. }
  simpl. 
  simpl in STEPS. red in STEPS. desc. red in STEPS. desc.
  assert (forall st' (STEP1: step tid st1 st') (STEP2: step tid st' st2)
            (NOT_IGT1: non_igt instr) (NOT_IGT2: non_igt instr'),
             pc st2 = pc st1 + 2) as STEPS2_HELPER. 
  { ins.
    assert (pc st' = pc st1 + 1) by (eapply regular_pc_change; eauto). 
    replace (pc st2) with (pc st' + 1); [omega| ]. 
    symmetry. eapply regular_pc_change; eauto.
    replace (instrs st') with (instrs st1); [congruence |].
    do 2 (red in STEP1; desc). auto. }
  
  inversion COMP_BLOCK; subst; simpl in *; red in STEPS; subst; desc.
  all: forward eapply STEPS2_HELPER; vauto.
Qed.

Lemma oseq_continuos st1 st2 tid PO
      (OSEQ: (oseq_step tid) st1 st2)
      (REACH: (step tid)＊ (init (instrs st1)) st1)
      (GOTO_RESTR: goto_addresses_restricted PO)
      (COMP: is_thread_compiled PO (instrs st1)):
  at_compilation_block st2.
Proof.
  red in OSEQ. desc.
  red in COMP. desc. 
  assert (exists bst1, st1 = bst2st bst1 /\ binstrs bst1 = BPI /\ bpc bst1 <= length BPI) as [bst1 [BST1 [BINSTRS1 BPC1]]].
  { apply acb_iff_bst; vauto. }
  assert (Some block = nth_error (binstrs bst1) (bpc bst1)) as BLOCK. 
  { apply st_bst_prog_blocks; vauto.
    exists PO. red in COMP. desc. auto. }
  forward eapply steps_pc_change as PC2; eauto.
  assert (instrs st2 = instrs st1) as SAME_INSTRS. 
  { symmetry. apply steps_same_instrs. exists tid. apply crt_num_steps. eauto. }  
  assert ((step tid)＊ (init (instrs st2)) st2) as REACH'.
  { rewrite SAME_INSTRS. eapply rt_trans; eauto. apply crt_num_steps. eauto. }
  
  assert (forall blc (STEPS: (step tid) ^^ (length blc) st1 st2)
            (BLC: Some blc = nth_error (binstrs bst1) (bpc bst1))
            (PC_PLUS: pc st2 = pc st1 + length blc),
             at_compilation_block st2) as NEXT_BLOCK. 
  { ins. forward eapply (@acb_iff_bst st2) as [_ ACB_IF_BST].
    2: { eauto. }
    { rewrite SAME_INSTRS. eauto. }
    apply ACB_IF_BST. 
    exists (bst_from_st st2 (binstrs bst1) (bpc bst1 + 1)).
    splits; auto.
    2: { simpl. apply le_lt_or_eq in BPC1. destruct BPC1; [omega |]. 
         subst.
         pose proof (proj2 (nth_error_None (binstrs bst1) (bpc bst1))).
         forward eapply H0; [omega| ]. ins. congruence. }      
    unfold bst2st. simpl.
    replace (flatten (binstrs bst1)) with (instrs st2).
    2: { rewrite <- (@steps_same_instrs st1 st2); [subst; eauto| ].
         exists tid. apply crt_num_steps. eauto. }
    red in OSEQ. desc.
    clear dependent oinstr. (* to avoid confusion with actual initial oinstr *)
    pose proof ll_index_shift. specialize H with (j := (bpc bst1 + 1)). specialize_full H; eauto. 
    { eapply COMPILED_NONEMPTY. Unshelve. 2: exact PO.
      red in COMP. desc. vauto. }
    { cut (bpc bst1 < length (binstrs bst1)); [ins; omega|].
      apply nth_error_Some, OPT_VAL. vauto. }
    cdes H. rewrite H1; auto.  
    subst st1. unfold bst2st in PC_PLUS. simpl in PC_PLUS. 
    rewrite <- PC_PLUS. 
    by destruct st2. }
  
  destruct PC2 as [PC2 | PC2]. 
  - eapply NEXT_BLOCK; eauto. 
  - desc. subst addr. (* subst block. *) simpl in *. 
    red in COMP. desc.
    subst BPI. 
    red in COMP. desc. 
    assert (exists oinstr, Some oinstr = nth_error PO (bpc bst1)) as [oinstr OINSTR]. 
    { apply OPT_VAL. apply nth_error_Some.
      replace (length PO) with (length (binstrs bst1)).
      { apply nth_error_Some, OPT_VAL. eauto. }
      symmetry. apply compilation_same_length. red; vauto. }    
    assert (exists block0, Some block0 = nth_error BPI0 (bpc bst1)) as [block0 BLOCK0].
    { apply OPT_VAL. apply nth_error_Some.
      replace (length BPI0) with (length (binstrs bst1)).
      { apply nth_error_Some, OPT_VAL. eauto. }
      symmetry. eapply Forall2_length. eauto. }
    assert (is_instruction_compiled oinstr block0) as COMP_BLOCK.
    { eapply Forall2_index; eauto. } 
    assert (block_corrected BPI0 block0 block) as CORR_BLOCK.
    { eapply Forall2_index; eauto. } 
    subst block.
    inversion CORR_BLOCK. inversion H3. subst. 
    inversion H2; vauto. subst addr.
    inversion COMP_BLOCK. subst. 
    simpl in OSEQ0. apply (same_relation_exp (seq_id_l (step tid))) in OSEQ0.
    do 2 (red in OSEQ0; desc).
    assert (instr = Instr.ifgoto cond (pc st2)).
    { forward eapply (@near_pc (Instr.ifgoto cond (pc st2)) _ 0) as AT_PC; eauto.
      { vauto. }
      { apply nth_error_Some, OPT_VAL. eauto. }
      rewrite Nat.add_0_r in AT_PC. congruence. }
    subst instr. 
    inversion ISTEP0. 
    all: try discriminate.
    destruct (Const.eq_dec (RegFile.eval_expr (regf (bst2st bst1)) expr) 0). 
    + eapply NEXT_BLOCK; eauto. simpl.
      apply (same_relation_exp (seq_id_l (step tid))).
      red. eexists. red. eauto.
    + subst.
      inversion CORR_BLOCK. subst. inversion H4; vauto.
      forward eapply acb_iff_bst as [_ ACB_IF_BST]. 
      { rewrite <- INSTRS. exists PO. simpl. red. splits; eauto. 
        vauto. }
      { eauto.  }
      apply ACB_IF_BST. 
      exists (bst_from_st st2 (binstrs bst1) addr0). splits; auto.
      2: { simpl.
           replace (length (binstrs bst1)) with (length PO).
           2: { apply compilation_same_length. vauto. }
           red in GOTO_RESTR. eapply GOTO_RESTR; eauto. }
      unfold bst2st. simpl.
      replace (flatten (binstrs bst1)) with (instrs st2).
      replace (length (flatten (firstn addr0 (binstrs bst1)))) with (length (flatten (firstn addr0 BPI0))).
      2: { apply SAME_STRUCT_PREF. eapply correction_same_struct; eauto. } 
      rewrite H5. by destruct st2. 
Qed. 


(* had to define it separately since otherwise Coq doesn't understand what P is *)
Definition StepProp n := forall st1 st2 tid PO (STEPS: (step tid) ^^ n st1 st2)
                           (REACH: (step tid)＊ (init (instrs st1)) st1)
                           bst1 (BST1: st1 = bst2st bst1)
                           bst2 (BST2: st2 = bst2st bst2)
                           (BOUND1: bpc bst1 <= length (binstrs bst1))
                           (BOUND2: bpc bst2 <= length (binstrs bst2))
                           (COMP: is_thread_block_compiled PO (binstrs bst1))
                           (GOTO_RESTR: goto_addresses_restricted PO)
                           (SAME_BINSTRS: binstrs bst1 = binstrs bst2),
    (omm_block_step_PO PO tid)＊ bst1 bst2.

Lemma oseq_between_acb: forall n, StepProp n.
Proof.
  apply strong_induction. 
  unfold StepProp. intros n IH. ins. desc.
  assert (at_compilation_block st1) as ACB1.
  { eapply acb_iff_bst; eauto.
    unfold is_thread_compiled_with. exists PO.
    split; [congruence| ]. rewrite BST1. simpl. congruence. }
  assert (at_compilation_block st2) as ACB2.
  { forward eapply (@acb_iff_bst st2) as [_ ACB_IF_BST]; eauto.
    { exists PO. red. split; eauto. rewrite SAME_BINSTRS. vauto. }
    { exists tid. replace (instrs st2) with (instrs st1).
      2: { subst. simpl. congruence. }
      eapply transitive_rt; eauto.
      apply crt_num_steps. eauto. }
    apply ACB_IF_BST. exists bst2. splits; vauto. congruence. }
  assert (bst2st bst1 = bst2st bst2 -> (omm_block_step_PO PO tid)＊ bst1 bst2) as WHEN_SAME_BST. 
  { intros SAME_BST2ST. 
    replace bst2 with bst1; [apply rt_refl| ].
    destruct bst2. destruct bst1. 
    f_equal; vauto. 
    rewrite <- SAME_BINSTRS in BOUND2.
    simpl in *. 
    eapply (@NONEMPTY_PREF _ binstrs); vauto. 
    eapply COMPILED_NONEMPTY; eauto. }
  
  unfold at_compilation_block in ACB1. desf. 
  2: { destruct n.
       { apply WHEN_SAME_BST. apply steps0 in STEPS. auto. }
       forward eapply (@steps_sub _ (step tid) (S n) _ _ 1) as [st' STEP];
         [omega | eauto |].
       apply (same_relation_exp (pow_1 (step tid))) in STEP.
       do 2 (red in STEP; desc). 
       cut (None = nth_error (instrs (bst2st bst1)) (pc (bst2st bst1))); [congruence| ].
       symmetry. apply nth_error_None. red in ACB1. omega. }
  pose proof (le_lt_dec (length block) n) as LEN. destruct LEN.
  { forward eapply (steps_split (step tid) (length block) (n - length block)) as SPLIT.
    { symmetry. apply le_plus_minus. auto. }
    apply SPLIT in STEPS. destruct STEPS as  [st' [PREV_STEPS NEXT_STEPS]]. clear SPLIT.
    assert (oseq_step tid (bst2st bst1) st') as OSEQ. 
    { red. eexists. eauto. }
    forward eapply (oseq_continuos OSEQ) as ACB'; vauto.
    assert (exists PO', is_thread_compiled PO' (instrs st')) as COMP'.
    { replace (instrs st') with (instrs (bst2st bst1)); vauto.
      apply steps_same_instrs. exists tid.
      (* remove duplicated proof *)
      red in OSEQ. desc. rewrite crt_num_steps. eexists. eauto. }
    assert (LEN': n - length block < n).
    { red in ACB1. desc. inversion COMP_BLOCK; subst; simpl in *; omega. }
    assert ((step tid)＊ (init (instrs st')) st') as REACH'.
    {  replace (instrs st') with (instrs (bst2st bst1)).
      2: { apply steps_same_instrs. exists tid. apply crt_num_steps. eauto. }
      eapply transitive_rt; eauto.
      apply crt_num_steps. eauto. }
    forward eapply (@acb_iff_bst st' (binstrs bst1)) as [BST_IF_ACB _]; eauto. 
    { exists PO. red. split; auto.
      replace (instrs st') with (instrs (bst2st bst1)); auto.
      apply steps_same_instrs; eauto. exists tid. apply crt_num_steps. eauto. }
    specialize (BST_IF_ACB ACB'). destruct BST_IF_ACB as [bst' [BST' [SAME_BINSTRS' BPC']]]. 
    forward eapply IH as IH_; eauto.
    { red in SAME_BINSTRS'. rewrite SAME_BINSTRS'. auto. }
    { congruence. }
    { congruence. }
    apply clos_trans_in_rt. apply t_step_rt. exists bst'. split; auto. 
    red. splits; vauto. 
    exists block. red. splits; auto.
    apply st_bst_prog_blocks; eauto. rewrite <- BST'. auto. }
  destruct (NPeano.Nat.eq_0_gt_0_cases n).
  { subst. apply steps0 in STEPS. apply WHEN_SAME_BST. auto. }
  forward eapply no_acb_between; eauto; [omega | vauto]. 
Qed. 

Definition is_block_terminal bst := bpc bst >= length (binstrs bst). 

Lemma steps_imply_ommblocks bfin PO tid
      (BPC_LIM: bpc bfin <= length (binstrs bfin))
      (GOTO_RESTR: goto_addresses_restricted PO)
      (COMP: is_thread_block_compiled PO (binstrs bfin)):
  let fin := (bst2st bfin) in 
  (step tid)＊ (init (instrs fin)) fin -> (omm_block_step_PO PO tid)＊ (binit (binstrs bfin)) bfin.
Proof.
  intros fin STEPS. apply crt_num_steps in STEPS as [n STEPS].
  eapply oseq_between_acb; eauto.
  2: { simpl. omega. }
  simpl. apply rt_refl. 
Qed. 

Lemma ommblocks_imply_steps bfin tid PO:
  let fin := (bst2st bfin) in 
  (omm_block_step_PO PO tid)＊ (binit (binstrs bfin)) bfin -> (step tid)＊ (init (instrs fin)) fin.
Proof.
  intros fin STEPS. apply crt_num_steps in STEPS as [n STEPS].
  generalize dependent bfin. induction n.
  { ins. red in STEPS. desc. subst. simpl.
    replace (init (flatten (binstrs bfin))) with (bst2st bfin); [apply rt_refl| ].
    rewrite <- STEPS. vauto. }
  ins. apply crt_num_steps.
  red in STEPS. desc.
  assert (binstrs bfin = binstrs z) as BINSTRS_SAME. 
  { red in STEPS0. desc. vauto. }
  rewrite BINSTRS_SAME in STEPS. specialize (IHn z STEPS).
  red in STEPS0. desc. red in BLOCK_STEP. desc.
  apply crt_num_steps in IHn. desc. 
  exists (n0 + length block). eapply steps_split; eauto.
  eexists. splits; eauto. rewrite BINSTRS_SAME. auto. 
Qed. 

End Steps.
