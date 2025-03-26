import Mathlib.Data.Matroid.IndepAxioms
import Mathlib.Data.Matroid.Dual
import Mathlib.Data.Matroid.Map
import Mathlib.Data.Matroid.Sum

import Seymour.Basic.Basic

open scoped Matrix Set.Notation


/-- Data representing a vector matroid. -/
structure VectorMatroid (α R : Type) where
  /-- Row indices. -/
  X : Set α
  /-- Col indices. -/
  Y : Set α
  /-- Full representation matrix. -/
  A : Matrix X Y R


variable {α R : Type}

/-- A set is independent in a vector matroid iff it corresponds to a linearly independent submultiset of columns. -/
def VectorMatroid.IndepCols [Semiring R] (M : VectorMatroid α R) (I : Set α) : Prop :=
  I ⊆ M.Y ∧ LinearIndepOn R M.Aᵀ (M.Y ↓∩ I)

/-- Our old (equivalent) definition. -/
private def VectorMatroid.IndepColsOld [Semiring R] (M : VectorMatroid α R) (I : Set α) : Prop :=
  ∃ hI : I ⊆ M.Y, LinearIndependent R (fun i : I => (M.A · (hI.elem i)))

private lemma VectorMatroid.indepCols_eq_indepColsOld [Semiring R] (M : VectorMatroid α R) :
    M.IndepCols = M.IndepColsOld := by
  ext I
  constructor <;> intro ⟨hI, hAI⟩ <;> use hI <;> let e : I ≃ M.Y ↓∩ I :=
      (Equiv.ofInjective hI.elem hI.elem_injective).trans (Equiv.Set.ofEq hI.elem_range)
  · exact (linearIndependent_equiv' e (by aesop)).← hAI
  · exact (linearIndependent_equiv' e (by aesop)).→ hAI

lemma VectorMatroid.indepCols_iff_elem [Semiring R] (M : VectorMatroid α R) (I : Set α) :
    M.IndepCols I ↔ ∃ hI : I ⊆ M.Y, LinearIndepOn R M.Aᵀ hI.elem.range := by
  unfold IndepCols HasSubset.Subset.elem
  aesop

lemma VectorMatroid.indepCols_iff_submatrix [Semiring R] (M : VectorMatroid α R) (I : Set α) :
    M.IndepCols I ↔ ∃ hI : I ⊆ M.Y, LinearIndependent R (M.A.submatrix id hI.elem)ᵀ :=
  M.indepCols_eq_indepColsOld ▸ Iff.rfl

lemma VectorMatroid.indepCols_iff_submatrix' [Semiring R] (M : VectorMatroid α R) (I : Set α) :
    M.IndepCols I ↔ ∃ hI : I ⊆ M.Y, LinearIndependent R (M.Aᵀ.submatrix hI.elem id) :=
  M.indepCols_eq_indepColsOld ▸ Iff.rfl


/-- Empty set is independent. -/
private theorem VectorMatroid.indepColsOld_empty [Semiring R] (M : VectorMatroid α R) :
    M.IndepColsOld ∅ :=
  ⟨M.Y.empty_subset, linearIndependent_empty_type⟩

/-- Empty set is independent. -/
theorem VectorMatroid.indepCols_empty [Semiring R] (M : VectorMatroid α R) :
    M.IndepCols ∅ :=
  M.indepCols_eq_indepColsOld ▸ M.indepColsOld_empty

/-- A subset of a independent set of columns is independent. -/
private theorem VectorMatroid.indepColsOld_subset [Semiring R] (M : VectorMatroid α R) (I J : Set α)
    (hMJ : M.IndepColsOld J) (hIJ : I ⊆ J) :
    M.IndepColsOld I :=
  have ⟨hJ, hM⟩ := hMJ
  ⟨hIJ.trans hJ, hM.comp hIJ.elem hIJ.elem_injective⟩

/-- A subset of an independent set of columns is independent. -/
theorem VectorMatroid.indepCols_subset [Semiring R] (M : VectorMatroid α R) (I J : Set α) (hMJ : M.IndepCols J) (hIJ : I ⊆ J) :
    M.IndepCols I :=
  M.indepCols_eq_indepColsOld ▸ M.indepColsOld_subset I J (M.indepCols_eq_indepColsOld ▸ hMJ) hIJ

set_option maxHeartbeats 400000 in
/-- A non-maximal independent set of columns can be augmented with another independent column. To see why `DivisionRing` is
    necessary, consider `(!![0, 1, 2, 3; 1, 0, 3, 2] : Matrix (Fin 2) (Fin 4) (ZMod 6))` as a counterexample.
    The set `{0}` is nonmaximal independent.
    The set `{2, 3}` is maximal independent.
    However, neither of the sets `{0, 2}` or `{0, 3}` is independent. -/
theorem VectorMatroid.indepCols_aug [DivisionRing R] (M : VectorMatroid α R) (I J : Set α)
    (hMI : M.IndepCols I) (hMI' : ¬Maximal M.IndepCols I) (hMJ : Maximal M.IndepCols J) :
    ∃ x ∈ J \ I, M.IndepCols (x ᕃ I) := by
  by_contra! non_aug
  rw [Maximal] at hMI'
  push_neg at hMI'
  obtain ⟨hI, I_indep⟩ := hMI
  obtain ⟨⟨hJ, J_indep⟩, hJ'⟩ := hMJ
  obtain ⟨K, hMK, IK, nKI⟩ := hMI' ⟨hI, I_indep⟩
  let I' : Set M.Y := { x : M.Y.Elem | x.val ∈ I }
  let J' : Set M.Y := { x : M.Y.Elem | x.val ∈ J }
  let Iᵥ : Set (M.X → R) := M.Aᵀ '' I'
  let Jᵥ : Set (M.X → R) := M.Aᵀ '' J'
  let Iₛ : Submodule R (M.X → R) := Submodule.span R Iᵥ
  let Jₛ : Submodule R (M.X → R) := Submodule.span R Jᵥ
  have Jᵥ_ss_Iₛ : Jᵥ ⊆ Iₛ
  · intro v ⟨x, hxJ, hxv⟩
    by_cases hvI : v ∈ Iᵥ
    · aesop
    · have x_in_J : ↑x ∈ J := hxJ
      have x_ni_I : ↑x ∉ I := by aesop
      have x_in_JwoI : ↑x ∈ J \ I := Set.mem_diff_of_mem x_in_J x_ni_I
      have hMxI : ¬M.IndepCols (↑x ᕃ I) := non_aug ↑x x_in_JwoI
      rw [VectorMatroid.IndepCols] at hMxI
      push_neg at hMxI
      have hnMxI : ¬LinearIndepOn R M.Aᵀ (M.Y ↓∩ (↑x ᕃ I)) := hMxI (Set.insert_subset (hJ hxJ) hI)
      have hYxI : M.Y ↓∩ (↑x ᕃ I) = x ᕃ I' := by aesop
      rw [hYxI] at hnMxI
      have I'_indep : LinearIndepOn R M.Aᵀ I' := I_indep
      by_contra! v_ni_Iₛ
      have : v ∉ Submodule.span R Iᵥ := v_ni_Iₛ
      have hx_ni_I : x ∉ I' := x_ni_I
      have Mx_ni_span_I : M.Aᵀ x ∉ Submodule.span R (M.Aᵀ '' I') := by aesop
      have xI_indep : LinearIndepOn R M.Aᵀ (x ᕃ I') := (linearIndepOn_insert hx_ni_I).mpr ⟨I'_indep, Mx_ni_span_I⟩
      exact hnMxI xI_indep
  have Iᵥ_ss_Jₛ : Iᵥ ⊆ Jₛ
  · intro v ⟨x, hxI, hxv⟩
    by_contra! v_ni_Jₛ
    have Mx_ni_span_J' : M.Aᵀ x ∉ Submodule.span R (M.Aᵀ '' J') := congr_arg (· ∈ Submodule.span R Jᵥ) hxv ▸ v_ni_Jₛ
    have x_ni_J' : x ∉ J'
    · by_contra! hx_in_J'
      have Mx_in_MJ' : M.Aᵀ x ∈ (M.Aᵀ '' J') := Set.mem_image_of_mem M.Aᵀ hx_in_J'
      have v_in_MJ' : v ∈ (M.Aᵀ '' J') := Set.mem_of_eq_of_mem hxv.symm Mx_in_MJ'
      exact v_ni_Jₛ (Submodule.mem_span.← (fun p a => a v_in_MJ'))
    have J'_indep : LinearIndepOn R M.Aᵀ J' := J_indep
    have xJ'_indep : LinearIndepOn R M.Aᵀ (x ᕃ J') := (linearIndepOn_insert x_ni_J').mpr ⟨J'_indep, Mx_ni_span_J'⟩
    have M_indep_xJ : M.IndepCols (↑x ᕃ J)
    · rw [VectorMatroid.IndepCols]
      constructor
      · exact Set.insert_subset (hI hxI) hJ
      · have hxJ' : M.Y ↓∩ (↑x ᕃ J) = x ᕃ J' := by aesop
        rw [hxJ']
        exact xJ'_indep
    have xJ_ss_J : ↑x ᕃ J ⊆ J := by simp_all
    exact x_ni_J' (xJ_ss_J (J.mem_insert ↑x))
  have Iₛ_eq_Jₛ : Iₛ = Jₛ := Submodule.span_eq_span Iᵥ_ss_Jₛ Jᵥ_ss_Iₛ
  obtain ⟨k, k_in_K, k_ni_I⟩ := Set.not_subset.→ nKI
  have kI_ss_K : (k ᕃ I) ⊆ K := Set.insert_subset k_in_K IK
  have M_indep_kI : M.IndepCols (k ᕃ I) := M.indepCols_subset (k ᕃ I) K hMK kI_ss_K
  have kI_ss_Y : k ᕃ I ⊆ M.Y := M_indep_kI.left
  have k_in_Y : k ∈ M.Y := kI_ss_Y (I.mem_insert k)
  let k' : M.Y.Elem := ⟨k, k_in_Y⟩
  by_cases hkJ' : k' ∈ J'
  · have k_in_JwoI : k ∈ J \ I := Set.mem_diff_of_mem hkJ' k_ni_I
    exact non_aug k k_in_JwoI M_indep_kI
  . have hkI' : M.Y ↓∩ (k ᕃ I) = ↑k' ᕃ I' := by aesop
    have k'_ni_I' : k' ∉ I' := k_ni_I
    rw [VectorMatroid.IndepCols, hkI'] at M_indep_kI
    obtain ⟨_, M_indep_kI⟩ := M_indep_kI
    have Mk'_ni_span_I' : M.Aᵀ k' ∉ Submodule.span R (M.Aᵀ '' I') := ((linearIndepOn_insert k'_ni_I').mp M_indep_kI).right
    have Mk'_ni_span_J' : M.Aᵀ k' ∉ Submodule.span R (M.Aᵀ '' J')
    · have span_I'_eq_span_J' : Submodule.span R (M.Aᵀ '' I') = Submodule.span R (M.Aᵀ '' J') := Iₛ_eq_Jₛ
      rw [←span_I'_eq_span_J']
      exact Mk'_ni_span_I'
    have J'_indep : LinearIndepOn R M.Aᵀ J' := J_indep
    have kJ'_indep : LinearIndepOn R M.Aᵀ (k' ᕃ J') := (linearIndepOn_insert hkJ').mpr ⟨J'_indep, Mk'_ni_span_J'⟩
    have hMkJ : M.IndepCols (k ᕃ J)
    · rw [VectorMatroid.IndepCols]
      constructor
      · exact Set.insert_subset k_in_Y hJ
      · have hkJ : M.Y ↓∩ (k ᕃ J) = k' ᕃ J' := by aesop
        rw [hkJ]
        exact kJ'_indep
    have kJ_ss_J : k ᕃ J ⊆ J := by simp_all
    exact hkJ' (kJ_ss_J (J.mem_insert k))

lemma linearIndepOn_sUnion_of_directedOn [Semiring R] {X Y : Set α} {A : Matrix Y X R} {s : Set (Set α)}
    (hs : DirectedOn (· ⊆ ·) s)
    (hA : ∀ a ∈ s, LinearIndepOn R A (Y ↓∩ a)) :
    LinearIndepOn R A (Y ↓∩ (⋃₀ s)) := by
  let s' : Set (Set Y.Elem) := (fun t : s => Y ↓∩ t).range
  have hss' : Y ↓∩ ⋃₀ s = s'.sUnion := by aesop
  rw [hss']
  apply linearIndepOn_sUnion_of_directed
  · intro x' hx' y' hy'
    obtain ⟨x, hxs, hxM⟩ : ∃ x ∈ s, x' = Y ↓∩ x := by aesop
    obtain ⟨y, hys, hyM⟩ : ∃ y ∈ s, y' = Y ↓∩ y := by aesop
    obtain ⟨z, _, hz⟩ := hs x hxs y hys
    exact ⟨Y ↓∩ z, by aesop, hxM ▸ Set.preimage_mono hz.left, hyM ▸ Set.preimage_mono hz.right⟩
  · aesop

/-- Every set of columns contains a maximal independent subset of columns. -/
theorem VectorMatroid.indepCols_maximal [Semiring R] (M : VectorMatroid α R) (I : Set α) :
    Matroid.ExistsMaximalSubsetProperty M.IndepCols I :=
  fun J hMJ hJI =>
    zorn_subset_nonempty
      { K : Set α | M.IndepCols K ∧ K ⊆ I }
      (fun c hcS chain_c _ =>
        ⟨⋃₀ c,
        ⟨⟨Set.sUnion_subset (fun _ hxc => (hcS hxc).left.left),
          linearIndepOn_sUnion_of_directedOn chain_c.directedOn (fun _ hxc => (hcS hxc).left.right)⟩,
          Set.sUnion_subset (fun _ hxc => (hcS hxc).right)⟩,
        fun _ => Set.subset_sUnion_of_mem⟩)
      J ⟨hMJ, hJI⟩

/-- `VectorMatroid` expressed as `IndepMatroid`. -/
private def VectorMatroid.toIndepMatroid [DivisionRing R] (M : VectorMatroid α R) : IndepMatroid α where
  E := M.Y
  Indep := M.IndepCols
  indep_empty := M.indepCols_empty
  indep_subset := M.indepCols_subset
  indep_aug := M.indepCols_aug
  indep_maximal S _ := M.indepCols_maximal S
  subset_ground _ := And.left

/-- `VectorMatroid` converted to `Matroid`. -/
def VectorMatroid.toMatroid [DivisionRing R] (M : VectorMatroid α R) : Matroid α :=
  M.toIndepMatroid.matroid

@[simp]
lemma VectorMatroid.toMatroid_E [DivisionRing R] (M : VectorMatroid α R) : M.toMatroid.E = M.Y :=
  rfl

@[simp low]
lemma VectorMatroid.toMatroid_indep [DivisionRing R] (M : VectorMatroid α R) : M.toMatroid.Indep = M.IndepCols :=
  rfl

@[simp]
lemma VectorMatroid.toMatroid_indep_iff_elem [DivisionRing R] (M : VectorMatroid α R) (I : Set α) :
    M.toMatroid.Indep I ↔ ∃ hI : I ⊆ M.Y, LinearIndepOn R M.Aᵀ hI.elem.range :=
  M.indepCols_iff_elem I

lemma VectorMatroid.toMatroid_indep_iff_submatrix [DivisionRing R] (M : VectorMatroid α R) (I : Set α) :
    M.toMatroid.Indep I ↔ ∃ hI : I ⊆ M.Y, LinearIndependent R (M.A.submatrix id hI.elem)ᵀ :=
  M.indepCols_iff_submatrix I

lemma VectorMatroid.toMatroid_indep_iff_submatrix' [DivisionRing R] (M : VectorMatroid α R) (I : Set α) :
    M.toMatroid.Indep I ↔ ∃ hI : I ⊆ M.Y, LinearIndependent R (M.Aᵀ.submatrix hI.elem id) :=
  M.indepCols_iff_submatrix' I
