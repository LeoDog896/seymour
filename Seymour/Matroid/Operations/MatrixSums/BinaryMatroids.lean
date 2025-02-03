import Mathlib.Data.Matroid.IndepAxioms

import Seymour.Basic
import Seymour.ForMathlib.SetTheory


/-- Data describing a binary matroid on the ground set `X ∪ Y` where `X` and `Y` are bundled.
Not in sync with `Matroid.Constructors.VectorMatroid/StandardRepr` currently! -/
structure StandardRepresentation (α : Type) [DecidableEq α] where
  /-- Basis elements → row indices of [`1 | B`] -/
  X : Set α
  /-- Non-basis elements → column indices of `B` -/
  Y : Set α
  /-- Necessary decidability -/
  decmemX : ∀ a, Decidable (a ∈ X)
  /-- Necessary decidability -/
  decmemY : ∀ a, Decidable (a ∈ Y)
  /-- Basis and nonbasis elements are disjoint -/
  hXY : X ⫗ Y
  /-- The standard representation matrix -/
  B : Matrix X Y Z2

-- Automatically infer decidability when `StandardRepresentation` is present.
attribute [instance] StandardRepresentation.decmemX
attribute [instance] StandardRepresentation.decmemY

variable {α : Type} [DecidableEq α] {X Y : Set α} [∀ a, Decidable (a ∈ X)] [∀ a, Decidable (a ∈ Y)]

/-- Given matrix `B`, whether the set of columns `S` in the (standard) representation [`1 | B`] `Z2`-independent. -/
def Matrix.IndepCols (B : Matrix X Y Z2) (S : Set α) : Prop :=
  ∃ hs : S ⊆ X ∪ Y, LinearIndependent Z2 ((Matrix.fromCols 1 B).submatrix id (Subtype.toSum ∘ hs.elem)).transpose


/-- The empty set of columns is linearly independent. -/
theorem Matrix.indepCols_empty {B : Matrix X Y Z2} : B.IndepCols ∅ := by
  use Set.empty_subset (X ∪ Y)
  exact linearIndependent_empty_type

/-- A subset of a linearly independent set of columns is linearly independent. -/
theorem Matrix.indepCols_subset {B : Matrix X Y Z2} (I J : Set α) (hBJ : B.IndepCols J) (hIJ : I ⊆ J) :
    B.IndepCols I := by
  obtain ⟨hJ, hB⟩ := hBJ
  use hIJ.trans hJ
  show LinearIndependent Z2 (fun i x => Matrix.fromCols 1 B x ((hJ.elem (Subtype.map id hIJ i)).toSum))
  apply hB.comp
  intro _ _ hf
  apply Subtype.eq
  simpa [Subtype.map] using hf

/-- A nonmaximal linearly independent set of columns can be augmented with another linearly independent column. -/
theorem Matrix.indepCols_augment {B : Matrix X Y Z2} (I J : Set α)
    (hBI : B.IndepCols I) (hBI' : ¬Maximal B.IndepCols I) (hBJ : Maximal B.IndepCols J) :
    ∃ x ∈ J \ I, B.IndepCols (x ᕃ I) := by
  sorry

/-- Any set of columns has the maximal subset property. -/
theorem Matrix.indepCols_maximal {B : Matrix X Y Z2} (S : Set α) :
    Matroid.ExistsMaximalSubsetProperty B.IndepCols S := by
  sorry

/-- Binary matroid given by its standard representation matrix expressed as `IndepMatroid`. -/
def Matrix.toIndepMatroid (B : Matrix X Y Z2) : IndepMatroid α where
  E := X ∪ Y
  Indep := B.IndepCols
  indep_empty := B.indepCols_empty
  indep_subset := B.indepCols_subset
  indep_aug := B.indepCols_augment
  indep_maximal S _ := B.indepCols_maximal S
  subset_ground _ := Exists.fst


/-- Binary matroid generated by its standard representation matrix, expressed as `Matroid`. -/
def Matrix.toMatroid (B : Matrix X Y Z2) : Matroid α := B.toIndepMatroid.matroid

/-- Convert `StandardRepresentation` to `Matroid`. -/
def StandardRepresentation.toMatroid (M : StandardRepresentation α) : Matroid α :=
  M.B.toMatroid

@[simp] -- API
lemma StandardRepresentation.E_eq (M : StandardRepresentation α) : M.toMatroid.E = M.X ∪ M.Y :=
  rfl

@[simp] -- API
lemma StandardRepresentation.indep_eq (M : StandardRepresentation α) : M.toMatroid.Indep = M.B.IndepCols :=
  rfl

/-- Registered conversion from `StandardRepresentation` to `Matroid`. -/
instance : Coe (StandardRepresentation α) (Matroid α) where
  coe := StandardRepresentation.toMatroid


/-- The binary matroid is regular iff the standard representation matrix has a totally unimodular signing. -/
def StandardRepresentation.IsRegular (M : StandardRepresentation α) : Prop :=
  ∃ B' : Matrix M.X M.Y ℚ, -- signed version of the standard representation matrix
    B'.IsTotallyUnimodular ∧ -- the signed standard representation matrix is TU
    ∀ i : M.X, ∀ j : M.Y, if M.B i j = 0 then B' i j = 0 else B' i j = 1 ∨ B' i j = -1 -- basically `|B| = |B'|`

/-- The binary matroid is regular iff the entire matrix has a totally unimodular signing. -/
lemma StandardRepresentation.isRegular_iff (M : StandardRepresentation α) :
    M.IsRegular ↔ ∃ B' : Matrix M.X M.Y ℚ,
      (Matrix.fromCols (1 : Matrix M.X M.X ℚ) B').IsTotallyUnimodular ∧ ∀ i : M.X, ∀ j : M.Y,
        if M.B i j = 0 then B' i j = 0 else B' i j = 1 ∨ B' i j = -1
    := by
  simp [StandardRepresentation.IsRegular, Matrix.one_fromCols_isTotallyUnimodular_iff]

-- Difficult!
lemma StandardRepresentation_toMatroid_isRegular_iff {M₁ M₂ : StandardRepresentation α} (hM : M₁.toMatroid = M₂.toMatroid) :
    M₁.IsRegular ↔ M₂.IsRegular := by
  sorry
