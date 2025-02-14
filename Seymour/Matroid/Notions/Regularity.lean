import Seymour.Matroid.Constructors.StandardRepresentation
import Seymour.ForMathlib.MatrixLI


/-- Matrix `A` is a TU signing of `U` iff `A` is TU and its entries are the same as in `U` up to signs.
    Do not ask `U.IsTotallyUnimodular` ... see `Matrix.overZ2_isTotallyUnimodular` for example! -/
def Matrix.IsTuSigningOf {X Y : Type} (A : Matrix X Y ℚ) {n : ℕ} (U : Matrix X Y (ZMod n)) : Prop :=
  A.IsTotallyUnimodular ∧ ∀ i j, |A i j| = (U i j).val

/-- Matrix `U` has a TU signing if there is a TU matrix whose entries are the same as in `U` up to signs. -/
def Matrix.HasTuSigning {X Y : Type} {n : ℕ} (U : Matrix X Y (ZMod n)) : Prop :=
  ∃ A : Matrix X Y ℚ, A.IsTuSigningOf U

variable {α : Type}

/-- The main definition of regularity: `M` is regular iff it is constructed from a `VectorMatroid` with a rational TU matrix. -/
def Matroid.IsRegular (M : Matroid α) : Prop :=
  ∃ X Y : Set α, ∃ A : Matrix X Y ℚ, A.IsTotallyUnimodular ∧ (VectorMatroid.mk X Y A).toMatroid = M

lemma Matrix.det_coe_ℤ_ℚ [DecidableEq α] [Fintype α] (A : Matrix α α ℤ) :
    ((A.det : ℤ) : ℚ) = (A.map (fun (a : ℤ) => (a : ℚ))).det := by
  simp [Matrix.det_apply]
  congr
  ext p
  if h1 : Equiv.Perm.sign p = 1 then
    simp [h1]
  else
    simp [Int.units_ne_iff_eq_neg.→ h1]
-- TODO can these two lemmas be generalized?
lemma Matrix.det_coe_ℤ_Z2 [DecidableEq α] [Fintype α] {A : Matrix α α ℤ} :
    ((A.det : ℤ) : Z2) = (A.map (fun (a : ℤ) => (a : Z2))).det := by
  simp [Matrix.det_apply]
  congr
  ext p
  if h1 : Equiv.Perm.sign p = 1 then
    simp [h1]
  else
    simp [Int.units_ne_iff_eq_neg.→ h1]

private lemma todoZ [DecidableEq α] [Fintype α] (A : Matrix α α ℤ)
    (hA : ∀ i j, A i j ∈ Set.range SignType.cast) (hA' : A.det ∈ Set.range SignType.cast) :
    A.det = (0 : ℤ) ↔ (Matrix.of (if A · · = 0 then 0 else 1)).det = (0 : Z2) := by
  have h0 : A.det = (0 : ℤ) ↔ (A.det : Z2) = (0 : Z2)
  · obtain ⟨s, hs⟩ := hA'
    cases s with
    | zero => exact ⟨congrArg Int.cast, fun _ => hs.symm⟩
    | pos | neg =>
      simp at hs
      rw [←hs]
      simp
  rw [h0, A.det_coe_ℤ_Z2]
  constructor -- TODO eliminate repeated code below
  · intro foo
    convert foo
    ext i j
    simp
    if hij0 : A i j = 0 then
      simp_all
    else
      simp [*]
      symm
      apply Fin2_eq_1_of_ne_0
      intro contr
      apply hij0
      obtain ⟨s, hs⟩ := hA i j
      cases s with
      | zero => exact hs.symm
      | pos | neg =>
        exfalso
        simp at hs
        rw [←hs] at contr
        simp at contr
  · intro foo
    convert foo
    ext i j
    simp
    if hij0 : A i j = 0 then
      simp_all
    else
      simp [*]
      apply Fin2_eq_1_of_ne_0
      intro contr
      apply hij0
      obtain ⟨s, hs⟩ := hA i j
      cases s with
      | zero => exact hs.symm
      | pos | neg =>
        exfalso
        simp at hs
        rw [←hs] at contr
        simp at contr

private lemma todo [DecidableEq α] [Fintype α] {A : Matrix α α ℚ}
    (hA : ∀ i j, A i j ∈ Set.range SignType.cast) (hA' : A.det ∈ Set.range SignType.cast) :
    A.det = (0 : ℚ) ↔ (Matrix.of (if A · · = 0 then 0 else 1)).det = (0 : Z2) := by
  have key : (((Matrix.of (if A · · = 0 then 0 else 1)).det : ℤ) : ℚ) = A.det
  · convert (Matrix.of (if A · · = 0 then 0 else 1)).det_coe_ℤ_ℚ
    ext i j
    simp
    obtain ⟨s, hs⟩ := hA i j
    cases s with
    | zero => simp_all only [Set.mem_range, SignType.zero_eq_zero, SignType.coe_zero, ite_true]
    | pos => aesop
    | neg => sorry -- TODO does not work this way; preserving `-1` is necessary now.
  convert todoZ (Matrix.of (if A · · = 0 then 0 else 1)) (by sorry) (by sorry)
  · simp [←key]
  · simp

/-- Every regular matroid is binary. -/
lemma Matroid.IsRegular.isBinary [DecidableEq α] {M : Matroid α} [Finite M.E] (hM : M.IsRegular) :
    ∃ V : VectorMatroid α Z2, V.toMatroid = M := by
  obtain ⟨X, Y, A, hA, rfl⟩ := hM
  use ⟨X, Y, Matrix.of (if A · · = 0 then 0 else 1)⟩
  ext I hI
  · simp
  have : Fintype I.Elem := Set.Finite.fintype (Finite.Set.subset (VectorMatroid.mk X Y A).toMatroid.E hI)
  clear hI
  simp only [VectorMatroid.toMatroid_indep, VectorMatroid.indepCols_iff_submatrix]
  constructor <;> intro ⟨hIY, hA'⟩ <;> use hIY <;>
      rw [Matrix.linearIndendent_iff_exists_submatrix_det] at hA' ⊢ <;>
      obtain ⟨f, hAf⟩ := hA' <;> use f <;> intro contr <;>
      rw [Matrix.transpose_submatrix, Matrix.submatrix_submatrix, Function.comp_id, Function.id_comp] at hAf contr <;>
      apply hAf <;> have hAT := hA.transpose <;> have hAf' := (hAT.submatrix hIY.elem f).apply <;>
      rw [Matrix.isTotallyUnimodular_iff_fintype] at hAT
  · rwa [todo hAf' (hAT ..)] at contr
  · rwa [todo hAf' (hAT ..)]

/-- Every regular matroid has a standard binary representation. -/
lemma Matroid.IsRegular.isBinaryStd [DecidableEq α] {M : Matroid α} [Finite M.E] (hM : M.IsRegular) :
    ∃ S : StandardRepr α Z2, S.toMatroid = M := by
  obtain ⟨V, hV⟩ := hM.isBinary
  obtain ⟨S, hS⟩ := V.exists_standardRepr
  rw [←hS] at hV
  exact ⟨S, hV⟩

/-- Matroid `M` that can be represented by a matrix over `Z2` with a TU signing -/
abbrev StandardRepr.HasTuSigning [DecidableEq α] (S : StandardRepr α Z2) : Prop :=
  S.B.HasTuSigning

/-- Matroid constructed from a standard representation is regular iff the binary matrix has a TU signing. -/
lemma StandardRepr.toMatroid_isRegular_iff_hasTuSigning [DecidableEq α] (S : StandardRepr α Z2) :
    S.toMatroid.IsRegular ↔ S.HasTuSigning := by
  sorry
