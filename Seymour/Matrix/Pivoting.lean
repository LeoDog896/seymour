import Seymour.Basic.SignTypeCast
import Seymour.Matrix.Basic

import Mathlib.LinearAlgebra.Matrix.SchurComplement

variable {X Y F : Type}

/-- The result of the pivot operation in a short tableau (without exchanging the indices that define the pivot).
    This definition makes sense only if `A x y` is nonzero. -/
def Matrix.shortTableauPivot [DivisionRing F] [DecidableEq X] [DecidableEq Y] (A : Matrix X Y F) (x : X) (y : Y) :
    Matrix X Y F :=
  Matrix.of <| fun i j =>
    if j = y then
      if i = x then
        1 / A x y
      else
        - A i y / A x y
    else
      if i = x then
        A x j / A x y
      else
        A i j - A i y * A x j / A x y

lemma Matrix.shortTableauPivot_elem_of_ne_ne [DivisionRing F] [DecidableEq X] [DecidableEq Y]
    (A : Matrix X Y F) {x : X} {y : Y} {i : X} {j : Y} (hix : i ≠ x) (hjx : j ≠ y) :
    A.shortTableauPivot x y i j = A i j - A i y * A x j / A x y := by
  simp [Matrix.shortTableauPivot, hix, hjx]

lemma Matrix.shortTableauPivot_row_pivot [DivisionRing F] [DecidableEq X] [DecidableEq Y]
    (A : Matrix X Y F) (x : X) (y : Y) :
    A.shortTableauPivot x y x =
    (fun j : Y => if j = y then 1 / A x y else A x j / A x y) := by
  ext
  simp [Matrix.shortTableauPivot]

lemma Matrix.shortTableauPivot_row_other [DivisionRing F] [DecidableEq X] [DecidableEq Y]
    (A : Matrix X Y F) (x : X) (y : Y) (i : X) (hix : i ≠ x) :
    A.shortTableauPivot x y i =
    (fun j : Y => if j = y then - A i y / A x y else A i j - A i y * A x j / A x y) := by
  ext
  simp [Matrix.shortTableauPivot, hix]


/-- Multiply the `x`th row of `A` by `c` and keep the rest of `A` unchanged. -/
private def Matrix.mulRow [DecidableEq X] [Mul F] (A : Matrix X Y F) (x : X) (c : F) :
    Matrix X Y F :=
  A.updateRow x (c • A x)

private lemma Matrix.mulRow_det [DecidableEq X] [Fintype X] [CommRing F] (A : Matrix X X F) (x : X) (c : F) :
    (A.mulRow x c).det = c * A.det := by
  rw [Matrix.mulRow, det_updateRow_smul, updateRow_eq_self]

private lemma Matrix.IsTotallyUnimodular.mulRow [DecidableEq X] [CommRing F] {A : Matrix X Y F}
    (hA : A.IsTotallyUnimodular) (x : X) {c : F} (hc : c ∈ SignType.cast.range) :
    (A.mulRow x c).IsTotallyUnimodular := by
  intro k f g hf hg
  if hi : ∃ i : Fin k, f i = x then
    obtain ⟨i, rfl⟩ := hi
    convert_to ((A.submatrix f g).updateRow i (c • (A.submatrix id g) (f i))).det ∈ SignType.cast.range
    · congr
      ext i' j'
      if hii : i' = i then
        simp [Matrix.mulRow, hii]
      else
        have hfii : f i' ≠ f i := (hii <| hf ·)
        simp [Matrix.mulRow, hii, hfii]
    rw [Matrix.det_updateRow_smul]
    apply in_signTypeCastRange_mul_in_signTypeCastRange hc
    have hAf := hA.submatrix f id
    rw [Matrix.isTotallyUnimodular_iff] at hAf
    convert hAf k id g
    rw [Matrix.submatrix_submatrix, Function.comp_id, Function.id_comp]
    exact (A.submatrix f g).updateRow_eq_self i
  else
    convert hA k f g hf hg using 2
    simp_all [Matrix.submatrix, Matrix.mulRow]

/-- Add `q` times the `x`th row of `A` to all rows of `A` except the `x`th row (where `q` is different for each row). -/
private def Matrix.addMultiples [DecidableEq X] [NonUnitalNonAssocSemiring F] (A : Matrix X Y F) (x : X) (q : X → F) :
    Matrix X Y F :=
  fun i : X => if i = x then A x else A i + q i • A x

private lemma Matrix.addMultiples_det [DecidableEq X] [Fintype X] [CommRing F] (A : Matrix X X F) (x : X) (q : X → F) :
    (A.addMultiples x q).det = A.det := by
  apply Matrix.det_eq_of_forall_row_eq_smul_add_const (fun i : X => if i = x then 0 else q i) x (by simp)
  unfold Matrix.addMultiples
  aesop

private lemma Matrix.IsTotallyUnimodular.addMultiples [DecidableEq X] [Field F] {A : Matrix X Y F}
    (hA : A.IsTotallyUnimodular) (x : X) (y : Y) (hxy : A x y ≠ 0) :
    (A.addMultiples x (- A · y / A x y)).IsTotallyUnimodular := by
  intro k f g hf hg
  -- If `x` is in the selected rows, the determinant won't change.
  if hx : ∃ r : Fin k, f r = x then
    obtain ⟨r, hr⟩ := hx
    convert_to ((A.submatrix f g).addMultiples r (fun i : Fin k => (- A (f i) y / A x y))).det ∈ SignType.cast.range using 2
    · ext i j
      if hir : i = r then
        simp [Matrix.addMultiples, hir, hr]
      else
        have hfi : f i ≠ x := (hir <| hf <| ·.trans hr.symm)
        simp [Matrix.addMultiples, hir, hr, hfi]
    rw [Matrix.addMultiples_det]
    exact hA k f g hf hg
  -- Else if `y` is in the selected columns, its column is all zeros, so the determinant is zero.
  else if hy : ∃ c : Fin k, g c = y then
    convert zero_in_signTypeCastRange
    obtain ⟨c, hc⟩ := hy
    apply Matrix.det_eq_zero_of_column_eq_zero c
    intro i
    rw [Matrix.submatrix_apply, hc]
    have hi : f i ≠ x := (hx ⟨i, ·⟩)
    simp_all [Matrix.addMultiples]
  -- Else perform the expansion on the `y` column, the smaller determinant is equal to ± the bigger determinant.
  else
    let f' : Fin k.succ → X := Fin.cons x f
    let g' : Fin k.succ → Y := Fin.cons y g
    have hf0 : f' 0 = x := rfl
    have hg0 : g' 0 = y := rfl
    have hf' : f'.Injective
    · intro a b hab
      by_cases ha : a = 0
      · by_cases hb : b = 0
        · rw [ha, hb]
        · exfalso
          let b' := b.pred hb
          simp [f', ha] at hab
          have hab' : f b' = x
          · convert hab.symm
            have hb' : b'.succ = b := Fin.succ_pred b hb
            rw [←hb']
            simp
          exact hx ⟨b', hab'⟩
      · by_cases hb : b = 0
        · exfalso
          let a' := a.pred ha
          simp [f', hb] at hab
          have hab' : f a' = x
          · convert hab
            have ha' : a'.succ = a := Fin.succ_pred a ha
            rw [←ha']
            simp
          exact hx ⟨a', hab'⟩
        · let a' := a.pred ha
          let b' := b.pred hb
          have ha' : a'.succ = a := Fin.succ_pred a ha
          have hb' : b'.succ = b := Fin.succ_pred b hb
          rw [←ha', ←hb'] at hab ⊢
          simp [f'] at hab
          rw [hf hab]
    have similar : ((A.addMultiples x (- A · y / A x y)).submatrix f' g').det ∈ SignType.cast.range
    · convert_to
        ((A.submatrix f' g').addMultiples 0 (fun i : Fin k.succ => (- A (f' i) y / A x y))).det ∈ SignType.cast.range
          using 2
      · ext i j
        if hi0 : i = 0 then
          simp [Matrix.addMultiples, hi0, hf0]
        else
          have hfi : f' i ≠ x := (hi0 <| hf' <| ·.trans hf0.symm)
          simp [Matrix.addMultiples, hi0, hf0, hfi]
      rw [Matrix.addMultiples_det]
      rw [Matrix.isTotallyUnimodular_iff] at hA
      exact hA k.succ f' g'
    have laplaced : ((A.addMultiples x (- A · y / A x y)).submatrix f' g').det =
        (A.addMultiples x (- A · y / A x y)) x y * ((A.addMultiples x (- A · y / A x y)).submatrix f g).det
    · rw [Matrix.det_succ_column_zero, sum_over_fin_succ_of_only_zeroth_nonzero]
      have my_pow_zero : (-1 : F) ^ (0 : Fin k.succ).val = 1 := pow_eq_one_iff_modEq.← rfl
      rw [my_pow_zero, one_mul]
      have hff : Fin.cons x f ∘ Fin.succ = f := rfl
      have hgg : Fin.cons y g ∘ Fin.succ = g := rfl
      simp [Matrix.submatrix_apply, f', g', hff, hgg]
      · intro i hi
        rw [Matrix.submatrix_apply]
        have hfi : f' i ≠ x := hf0 ▸ (hi <| hf' <| ·)
        simp_all [Matrix.addMultiples]
    have eq_Axy : (A.addMultiples x (- A · y / A x y)) x y = A x y
    · simp [Matrix.addMultiples]
    rw [laplaced, eq_Axy] at similar
    if hAxy : A x y = 1 then
      simpa [hAxy] using similar
    else if hAyx : A x y = -1 then
      exact in_signTypeCastRange_of_neg_one_mul (hAyx ▸ similar)
    else
      exfalso
      obtain ⟨s, hs⟩ := hA.apply x y
      cases s with
      | zero => exact hxy hs.symm
      | pos => exact hAxy hs.symm
      | neg => exact hAyx hs.symm

/-- The small tableau consists of all columns but `x`th from the original matrix and the `y`th column of the square matrix. -/
private def Matrix.getShortTableau [DecidableEq Y] (A : Matrix X (X ⊕ Y) F) (x : X) (y : Y) :
    Matrix X Y F :=
  Matrix.of (fun i : X => fun j : Y => if j = y then A i ◩x else A i ◪j)

private lemma Matrix.IsTotallyUnimodular.getShortTableau [DecidableEq Y] [CommRing F]
    {A : Matrix X (X ⊕ Y) F} (hA : A.IsTotallyUnimodular) (x : X) (y : Y) :
    (A.getShortTableau x y).IsTotallyUnimodular := by
  convert
    hA.submatrix id (fun j : Y => if j = y then ◩x else ◪j)
  unfold Matrix.getShortTableau
  aesop

private lemma Matrix.shortTableauPivot_eq [DecidableEq X] [DecidableEq Y] [Field F] (A : Matrix X Y F) (x : X) (y : Y) :
    A.shortTableauPivot x y =
    ((A.prependId.addMultiples x (- A · y / A x y)).getShortTableau x y).mulRow x (1 / A x y) := by
  ext i j
  if hj : j = y then
    by_cases hi : i = x <;>
      simp [Matrix.shortTableauPivot, Matrix.addMultiples, Matrix.getShortTableau, Matrix.mulRow, hj, hi]
  else
    if hi : i = x then
      simp [Matrix.shortTableauPivot, Matrix.addMultiples, Matrix.getShortTableau, Matrix.mulRow, hj, hi]
      exact div_eq_inv_mul (A x j) (A x y)
    else
      simp [Matrix.shortTableauPivot, Matrix.addMultiples, Matrix.getShortTableau, Matrix.mulRow, hj, hi]
      ring

/-- Pivoting preserves total unimodularity. -/
lemma Matrix.IsTotallyUnimodular.shortTableauPivot [DecidableEq X] [DecidableEq Y] [Field F] {A : Matrix X Y F}
    (hA : A.IsTotallyUnimodular) {x : X} {y : Y} (hxy : A x y ≠ 0) :
    (A.shortTableauPivot x y).IsTotallyUnimodular := by
  rw [Matrix.shortTableauPivot_eq]
  have hAxy : 1 / A x y ∈ SignType.cast.range
  · rw [inv_eq_self_of_in_signTypeCastRange] <;> exact hA.apply x y
  exact (((hA.one_fromCols).addMultiples x ◪y hxy).getShortTableau x y).mulRow x hAxy

#print axioms Matrix.IsTotallyUnimodular.shortTableauPivot

lemma Matrix.submatrix_shortTableauPivot [DecidableEq X] [DecidableEq Y] {X' Y' : Type} [DecidableEq X'] [DecidableEq Y']
    [DivisionRing F] {f : X' → X} {g : Y' → Y} (A : Matrix X Y F) (hf : f.Injective) (hg : g.Injective) (x : X') (y : Y') :
    (A.submatrix f g).shortTableauPivot x y = (A.shortTableauPivot (f x) (g y)).submatrix f g := by
  ext i j
  have hfix : f i = f x → i = x := (hf ·)
  have hgjy : g j = g y → j = y := (hg ·)
  unfold Matrix.shortTableauPivot
  aesop

lemma Matrix.shortTableauPivot.submatrix_succAbove_pivot_apply [Field F] {k : ℕ} {A : Matrix (Fin k.succ) (Fin k.succ) F}
    {r c : Fin k.succ} (a b : Fin k) : (A.shortTableauPivot r c).submatrix r.succAbove c.succAbove a b = (
        A (r.succAbove a) (c.succAbove b) - A (r.succAbove a) c * A r (c.succAbove b) / A r c) := by
  simp [shortTableauPivot, c.succAbove_ne b, r.succAbove_ne a]

lemma Matrix.shortTableauPivot.submatrix_eq [Field F] {k : ℕ} {A : Matrix (Fin k.succ) (Fin k.succ) F}
    {r c : Fin k.succ} : (A.shortTableauPivot r c).submatrix r.succAbove c.succAbove =
      Matrix.of fun (i j : Fin k) => A (r.succAbove i) (c.succAbove j) - A (r.succAbove i) c * A r (c.succAbove j) / A r c := by
  ext i j
  exact Matrix.shortTableauPivot.submatrix_succAbove_pivot_apply i j

noncomputable abbrev Fin.reindexingAux {n : ℕ} (i : Fin n.succ) : Fin 1 ⊕ Fin n → Fin n.succ := (·.casesOn i i.succAbove)

lemma Fin.reindexingAux_bijective {n : ℕ} (i : Fin n.succ) : Function.Bijective i.reindexingAux :=
  ⟨fun a b hab => by
      cases a with
      | inl a₁ =>
        cases b with
        | inl b₁ =>
          congr
          apply Fin1_eq_Fin1
        | inr bₙ =>
          symm at hab
          absurd i.succAbove_ne bₙ
          simpa using hab
      | inr aₙ =>
        cases b with
        | inl b₁ =>
          absurd i.succAbove_ne aₙ
          simpa using hab
        | inr bₙ =>
          simpa using hab,
    fun c => by
      if hic : i = c then
        use ◩0
        simpa using hic
      else
        aesop⟩

noncomputable def Fin.reindexing {n : ℕ} (i : Fin n.succ) : Fin 1 ⊕ Fin n ≃ Fin n.succ :=
  Equiv.ofBijective i.reindexingAux i.reindexingAux_bijective

lemma Fin.reindexing_symm_eq_left {n : ℕ} (i k : Fin n.succ) (j : Fin 1) :
    i.reindexing.symm k = ◩j ↔ i = k := by
  unfold Fin.reindexing
  constructor <;> intro h
  on_goal 1 =>
    apply_fun i.reindexingAux at h
    rw [Equiv.ofBijective_apply_symm_apply i.reindexingAux i.reindexingAux_bijective k] at h
  on_goal 2 =>
    apply_fun i.reindexingAux using i.reindexingAux_bijective.1
    rw [Equiv.ofBijective_apply_symm_apply i.reindexingAux i.reindexingAux_bijective k]
  all_goals
    simp [h]

lemma Fin.reindexing_symm_eq_right {n : ℕ} (i k : Fin n.succ) (j : Fin n) :
    i.reindexing.symm k = ◪j ↔ k = (i.succAbove j) := by
  unfold Fin.reindexing
  constructor <;> intro h
  on_goal 1 =>
    apply_fun i.reindexingAux at h
    rw [Equiv.ofBijective_apply_symm_apply i.reindexingAux i.reindexingAux_bijective k] at h
  on_goal 2 =>
    apply_fun i.reindexingAux using i.reindexingAux_bijective.1
    rw [Equiv.ofBijective_apply_symm_apply i.reindexingAux i.reindexingAux_bijective k]
  all_goals
    simp [h]

lemma lemma1 [Field F] {k : ℕ} {A : Matrix (Fin k.succ) (Fin k.succ) F} {r c : Fin k.succ} (hArc : A r c ≠ 0) :
    ∃ f : Fin k → Fin k.succ, ∃ g : Fin k → Fin k.succ, f.Injective ∧ g.Injective ∧
      ((A.shortTableauPivot r c).submatrix f g).det = A.det / A r c := by
  use r.succAbove, c.succAbove
  use Fin.succAbove_right_injective, Fin.succAbove_right_injective
  rw [Matrix.shortTableauPivot.submatrix_eq]
  conv in _ / _ => rw [div_eq_mul_inv _ (A r c)]

  let M₁ := Matrix.of fun (i j : Fin k) => A (r.succAbove i) (c.succAbove j)
  let M₂ := Matrix.of fun (i : Fin k) (j : Fin 1) => A (r.succAbove i) c
  let M₃ := Matrix.of fun (i : Fin 1) (j : Fin k) => A r (c.succAbove j)
  let M₄ := !![A r c]

  have hAM₁ : ∀ i j, A (r.succAbove i) (c.succAbove j) = M₁ i j := fun _ _ => rfl
  have hAM₂ : ∀ i, A (r.succAbove i) c = M₂ i 0 := fun _ => rfl
  have hAM₃ : ∀ j, A r (c.succAbove j) = M₃ 0 j := fun _ => rfl
  have hAM₄ : (A r c) = (M₄ 0 0) := rfl

  have hiAM₄ : M₄⁻¹ = !![(A r c)⁻¹] := by
    ext i j
    suffices ¬i = j → 0 = A r c by simpa [M₄, Matrix.diagonal]
    refine (absurd ?_ ·)
    rw [Fin.eq_zero i, Fin.eq_zero j]

  conv in _ - _ * _ => rw [hAM₁ i j, hAM₂ i, hAM₃ j, hAM₄]

  have hM : (Matrix.of fun i j => M₁ i j - M₂ i 0 * M₃ 0 j * (M₄ 0 0)⁻¹) = M₁ - (M₂) * (M₄)⁻¹ * M₃ := by
    ext i j
    have : A (r.succAbove i) c * M₃ 0 j * (A r c)⁻¹ = A (r.succAbove i) c * (A r c)⁻¹ * M₃ 0 j := by ring
    simpa [hiAM₄, Matrix.mul_apply, M₂, M₄]

  have : Invertible M₄ := Matrix.invertibleOfLeftInverse M₄ M₄⁻¹ (by
    rw [hiAM₄]
    unfold M₄
    ext i j
    rw [Fin.eq_zero i, Fin.eq_zero j]
    simp [IsUnit.inv_mul_cancel (IsUnit.mk0 _ hArc)])

  rw [
    hM, IsUnit.eq_div_iff hArc.isUnit, mul_comm, hAM₄,
    show M₄ 0 0 * (M₁ - M₂ * M₄⁻¹ * M₃).det = M₄.det * (M₁ - M₂ * M₄⁻¹ * M₃).det by simp,
    ← Matrix.invOf_eq_nonsing_inv M₄, ← Matrix.det_fromBlocks₁₁ M₄ M₃ M₂ M₁
  ]

  have hA : A = (Matrix.fromBlocks M₄ M₃ M₂ M₁).submatrix r.reindexing.symm c.reindexing.symm
  · ext i j
    rw [Matrix.submatrix_apply]
    rcases hr : r.reindexing.symm i with (ri | ri) <;> rcases hc : c.reindexing.symm j with (cj | cj)
    on_goal 1 => rw [Matrix.fromBlocks_apply₁₁]
    on_goal 2 => rw [Matrix.fromBlocks_apply₁₂]
    on_goal 3 => rw [Matrix.fromBlocks_apply₂₁]
    on_goal 4 => rw [Matrix.fromBlocks_apply₂₂]
    all_goals
      try rw [Fin.reindexing_symm_eq_left] at hr
      try rw [Fin.reindexing_symm_eq_left] at hc
      try rw [Fin.reindexing_symm_eq_right] at hr
      try rw [Fin.reindexing_symm_eq_right] at hc
      subst hr hc
      simp [M₄, M₃, M₂, M₁]
  rw [hA]

  sorry

lemma corollary1 [Field F] {k : ℕ} {A : Matrix (Fin k.succ) (Fin k.succ) F}
    (hA : A.det ∉ SignType.cast.range) (i j : Fin k.succ) (hAij : A i j = 1 ∨ A i j = -1) :
    ∃ f : Fin k → Fin k.succ, ∃ g : Fin k → Fin k.succ, f.Injective ∧ g.Injective ∧
      ((A.shortTableauPivot i j).submatrix f g).det ∉ SignType.cast.range := by
  have hArc0 : A i j ≠ 0
  · cases hAij with
    | inl h1 =>
      rw [h1]
      norm_num
    | inr h9 =>
      rw [h9]
      norm_num
  obtain ⟨f, g, hf, hg, hAfg⟩ := lemma1 hArc0
  use f, g, hf, hg
  rw [hAfg]
  cases hAij with
  | inl h1 =>
    rw [h1, div_one]
    exact hA
  | inr h9 =>
    rw [h9, div_neg, div_one]
    exact (hA <| in_signTypeCastRange_of_neg ·)

lemma Matrix.shortTableauPivot_zero {X' Y' : Type} [DecidableEq X] [DecidableEq Y] [DecidableEq X'] [DivisionRing F]
    (B : Matrix X Y F) (x : X') (y : Y) (f : X' → X) (g : Y' → Y) (hg : y ∉ g.range) (hBfg : ∀ i j, B (f i) (g j) = 0) :
    ∀ i : X', ∀ j : Y', (B.shortTableauPivot (f x) y) (f i) (g j) = 0 := by
  unfold Matrix.shortTableauPivot
  aesop

lemma Matrix.shortTableauPivot_submatrix_zero_external_row [DivisionRing F] [DecidableEq X] [DecidableEq Y] (A : Matrix X Y F)
    (r : X) (c : Y) {X' Y' : Type} (f : X' → X) (g : Y' → Y) (hf : r ∉ f.range) (hg : c ∉ g.range) (hAr : ∀ j, A r (g j) = 0) :
    (A.shortTableauPivot r c).submatrix f g = A.submatrix f g := by
  unfold shortTableauPivot
  aesop
