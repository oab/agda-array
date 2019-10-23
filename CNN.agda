
open import Array
open import Array.APL

open import Data.Nat
open import Data.Nat.Properties
open import Data.Nat.DivMod hiding (_/_)
open import Data.Fin using (Fin; zero; suc; toℕ)
open import Data.Vec
open import Data.Vec.Properties
open import Relation.Binary.PropositionalEquality
open import Data.Product

open import Function
open import Relation.Nullary
open import Relation.Nullary.Decidable
open import Data.Unit using (⊤)

open import Agda.Builtin.Float


a≤b⇒b≡c⇒a≤c : ∀ {a b c} → a ≤ b → b ≡ c → a ≤ c
a≤b⇒b≡c⇒a≤c a≤b refl = a≤b

a≤b⇒a≡c⇒b≡d⇒c≤d : ∀ {a b c d} → a ≤ b → a ≡ c → b ≡ d → c ≤ d
a≤b⇒a≡c⇒b≡d⇒c≤d a≤b refl refl = a≤b


A<B⇒B≤C⇒A≤C : ∀ {n}{ix s s₁ : Ar ℕ 1 (n ∷ [])}
             → ix <a s → s₁ ≥a s → s₁ ≥a ix
A<B⇒B≤C⇒A≤C {ix = imap x} {imap x₁} {imap x₂} ix<s ix≤s₁ iv = ≤-trans (<⇒≤ $ ix<s iv) (ix≤s₁ iv)

A≥B⇒A≡C⇒C≥B : ∀ {d s}{A B C : Ar ℕ d s}
             → A ≥a B → A =a C → C ≥a B
A≥B⇒A≡C⇒C≥B {A = imap x} {imap x₁} {imap x₂} A≥B A≡C iv rewrite (sym $ A≡C iv) = A≥B iv


a-s[b]+1≡a-b : ∀ {a b} → b < a →  a ∸ suc b + 1 ≡ a ∸ b
a-s[b]+1≡a-b {a} {b} pf = begin
                     a ∸ suc (b) + 1  ≡⟨ sym $ +-∸-comm 1 pf ⟩
                     a + 1 ∸ suc b    ≡⟨ cong₂ _∸_ (+-comm a 1) (refl {x = suc b}) ⟩
                     a ∸ b
                   ∎
                   where open ≡-Reasoning


conv-ix-inb : ∀ {n}{ix s s₁ : Ar ℕ 1 (n ∷ [])}
            → (ix<s : ix <a s)
            → (s₁≥s : s₁ ≥a s)
            → (s₁ -ₙ ix) {≥ = A<B⇒B≤C⇒A≤C {s₁ = s₁} ix<s s₁≥s}
               ≥a ((s₁ -ₙ s) {≥ = s₁≥s} +ₙ (scal 1))
conv-ix-inb {ix = imap ix} {imap s} {imap s₁} ix<s s₁≥s iv =
       let
         s₁-[1+ix]≥s₁-s = ∸-monoʳ-≤ (s₁ iv) (ix<s iv)
         s₁-[1+ix]+1≥s₁-s+1 = +-monoˡ-≤ 1 s₁-[1+ix]≥s₁-s
       in a≤b⇒b≡c⇒a≤c s₁-[1+ix]+1≥s₁-s+1 (a-s[b]+1≡a-b {a = s₁ iv} {b = ix iv} (≤-trans (ix<s iv) (s₁≥s iv))) 



undo-sa-as : ∀ {n} {s s₁ : Vec ℕ n}{ix : Ar ℕ 1 (n ∷ [])}{≥1}
     → ((imap (λ iv → lookup s₁ (ix-lookup iv zero)) -ₙ ix) {≥ = ≥1})
       =a imap (λ z → lookup (a→s ((imap (λ iv → lookup s₁ (ix-lookup iv zero)) -ₙ ix) {≥ = ≥1}))
                             (ix-lookup z zero))
undo-sa-as {s₁ = s₁} {ix = (imap ix)} {≥1} iv = sym $ s→a∘a→s ((s→a s₁ -ₙ imap ix) {≥ = ≥1}) iv

conv : ∀ {n s s₁}
       → Ar Float n s
       → Ar Float n s₁
       → {s₁≥s : s→a s₁ ≥a s→a s}
       → let sr = a→s $ (s→a s₁ -ₙ s→a s) {≥ = s₁≥s} +ₙ scal 1
         in Ar Float n sr
conv {n = n} {s = s} {s₁ = s₁} w a {s₁≥s} = let
               sr = (s→a s₁ -ₙ s→a s) {≥ = s₁≥s} +ₙ scal 1
               idxs = ι ρ w
               
               rots ix ix<s = let
                  ~ix≥ρa = A<B⇒B≤C⇒A≤C ix<s s₁≥s
                  ix↓a = (ix ↓ a) {pf = ~ix≥ρa}
                  ~ix-inb = conv-ix-inb {s₁ = s→a s₁} ix<s s₁≥s
                  ~ρix↓a≥sr = A≥B⇒A≡C⇒C≥B
                                ~ix-inb
                                (undo-sa-as {s = s} {s₁ = s₁} {≥1 = ~ix≥ρa})
                  in
                  (sr ↑ ix↓a) {pf = ~ρix↓a≥sr } 
               
               rots-unw ix,ix<s = (let
                                     ix , ix<s = ix,ix<s
                                    in rots ix ix<s)
               r = rots-unw ¨ idxs
               mul = mapₐ₂ (λ weight arr → arr ×⟨ n-n ⟩ᵣ (cst weight)) w (subst-ar (a→s∘s→a s) r)
               res = reduce-1d (, mul) _+ᵣ_ (cst 0.0)
              in res 

cex₁ = conv (cst {s = 1 ∷ []} 1.0)
           (imap {s = 2 ∷ []} λ { (zero ∷ []) → 2.0 ; (suc zero ∷ []) → 3.0})
           {s₁≥s = λ { (zero ∷ []) → s≤s z≤n} }

cex₂ = conv (mkempty (3 ∷ 0 ∷ []) refl)
           (cst {s = 5 ∷ 0 ∷ []} 1.0)
           {λ { (zero ∷ []) → s≤s (s≤s (s≤s z≤n)) ;
                (suc zero ∷ []) → z≤n}}

-- blog←{⍺×⍵×1-⍵}
blog : ∀ {n s} → Ar Float n s → Ar Float n s → Ar Float n s
blog α ω = α ×ᵣ ω ×ᵣ (scal 1.0) -ᵣ ω

-- backbias←{+/,⍵}
backbias : ∀ {n s} → Ar Float n s → Scal Float
backbias ω = _+ᵣ_ / , ω 

-- XXX we can define unary -ᵣ and ÷ᵣ to make it even nicer.
-- logistic←{÷1+*-⍵}
logistic : ∀ {n s} → Ar Float n s → Ar Float n s
logistic {s} ω = (scal 1.0) ÷ᵣ (scal 1.0) +ᵣ *ᵣ (scal 0.0) -ᵣ ω

-- XXX Note that even though we had to specify n-n instances
--     explicitly, we didn't truly mimic the APL expression below.
--     As per APL semantics, meansqerr accepts the combination
--     of arguments 0-n, n-n and n-0.  So the fact that we had
--     to specialise suggests that we didn't truly implement
--     the original behaviour.
-- meansqerr←{÷∘2+/,(⍺-⍵)*2}
meansqerr : ∀ {n s} → Ar Float n s → Ar Float n s → Scal Float
meansqerr α ω = 
    _÷⟨ n-n ⟩ᵣ (cst 2.0) $ (_+ᵣ_ / , (α -⟨ n-n ⟩ᵣ ω) ×ᵣ (α -⟨ n-n ⟩ᵣ ω))



-- need ix / 2 < m
-- have ix < m * 2
-- 0 < 1 , but 0/2 ≮ 1/2

--postulate
  -- This can be found in the newer stdlib.
  --m*n/n≡m : ∀ m n {≢0} → ((m * n) div n) {≢0} ≡ m

a<b⇒ak<bk : ∀ {a b k} → a < b → a * suc k < b * suc k
a<b⇒ak<bk {k = k} a<b = *-monoˡ-< k a<b

a<b⇒0<b : ∀ {a b} → a < b → zero < b
a<b⇒0<b {a} a<b = ≤-trans (s≤s z≤n) a<b

a<b⇒c≤a⇒c<b : ∀ {a b c} → a < b → c ≤ a → c < b
a<b⇒c≤a⇒c<b a<b z≤n = a<b⇒0<b a<b
a<b⇒c≤a⇒c<b (s≤s a<b) (s≤s c≤a) = s≤s (a<b⇒c≤a⇒c<b a<b c≤a)


pattern I0 = (zero ∷ [])
pattern I1 = (suc zero ∷ [])
pattern I2 = (suc (suc zero) ∷ [])
pattern I3 = (suc (suc (suc zero)) ∷ [])


-- backavgpool←{2⌿2/⍵÷4}⍤2
backavgpool : ∀ {s}
              → Ar Float 2 s
              → Ar Float 2 $ a→s (s→a s ×ₙ (scal 2))
backavgpool {m ∷ n ∷ []} (imap f) = imap (λ iv →
                                           let
                                             ix , ix<r = ix→a iv
                                             px = (ix ÷ₙ (cst 2)) {≥0 = λ _ → s≤s z≤n}
                                             pv = a→ix px (s→a (m ∷ n ∷ [])) λ jv →
                                                       let
                                                         x = a<b⇒c≤a⇒c<b (ix<r jv) (m/n*n≤m _ 2)
                                                         y = a≤b⇒b≡c⇒a≤c x (*-lookup {jv = jv}{m = m}{n = n})
                                                       in    *-cancelʳ-< _ _ y
                                           in f pv) ÷ᵣ (scal 4.0)

  where
    *-lookup : ∀ {jv : Ix 1 (2 ∷ [])}{m n}
             → lookup (m * 2 ∷ n * 2 ∷ []) (ix-lookup jv zero)
             ≡ lookup (m ∷ n ∷ []) (ix-lookup jv zero) * 2
    *-lookup {jv = I0} = refl
    *-lookup {jv = I1} = refl



a≤a*b : ∀ {a b} → a ≤ a * suc b 
a≤a*b {a} {b = zero} rewrite (*-identityʳ a) = ≤-refl
a≤a*b {a} {b = suc b} = ≤-trans a≤a*b (*-monoʳ-≤ a (≤-step ≤-refl))

a≤b⇒c≤a⇒c≤b : ∀ {a b c} → a ≤ b → c ≤ a → c ≤ b
a≤b⇒c≤a⇒c≤b {a} {b} {c} a≤b c≤a = ≤-trans c≤a a≤b

≡⇒≤ : ∀ {a b} → a ≡ b → a ≤ b
≡⇒≤ refl = ≤-refl

-- This should be perfectly generaliseable --- instead of 2
-- we can use any m>0
xthm : ∀ {a b k} → a < b → k < 2 → a * 2 + k < b * 2
xthm {a} {b} {zero}  a<b k<2 rewrite (+-identityʳ (a * 2)) | (*-comm a 2) | (*-comm b 2) = *-monoʳ-< 1 a<b
xthm {a} {b} {suc zero} a<b k<2 = ≤-trans (s≤s (≡⇒≤ (+-comm _ 1))) (*-monoˡ-≤ 2 a<b) 
xthm {a} {b} {suc (suc k)} a<b (s≤s (s≤s ()))

XTHM : ∀ {n s}{a b k : Ar ℕ n s} → a <a b → k <a (cst 2) → ((a ×ₙ (scal 2)) +ₙ k) <a (b ×ₙ (scal 2))
XTHM {a = imap a} {imap b} {imap k} a<b k<2 = λ iv → xthm (a<b iv) (k<2 iv)


-- avgpool←{÷∘4{+/,⍵}⌺(2 2⍴2)⍤2⊢⍵}
avgpool : ∀ {s}
          → Ar Float 2 $ a→s (s→a s ×ₙ (scal 2))
          → Ar Float 2 s
avgpool {s} (imap p) = imap (λ iv → let
                         sh = (s→a s ×ₙ scal 2)
                         ix , ix<s = ix→a iv
                         bx = ix ×ₙ scal 2
                         s-00 = s→a (0 ∷ 0 ∷ [])
                         i1 = a→ix (bx +ₙ s-00) sh (XTHM {k = s-00} ix<s λ { (zero ∷ []) → s≤s z≤n;
                                                                             (suc zero ∷ []) → s≤s z≤n})
                         s-01 = s→a (0 ∷ 1 ∷ [])
                         i2 = a→ix (bx +ₙ s-01) sh (XTHM {k = s-01} ix<s λ { (zero ∷ []) → s≤s z≤n ;
                                                                             (suc zero ∷ []) → s≤s (s≤s z≤n) })
                         s-10 = s→a (1 ∷ 0 ∷ [])
                         i3 = a→ix (bx +ₙ s-10) sh (XTHM {k = s-10} ix<s λ { (zero ∷ []) → s≤s (s≤s z≤n) ;
                                                                             (suc zero ∷ []) → s≤s z≤n })
                         s-11 = s→a (1 ∷ 1 ∷ [])
                         i3 = a→ix (bx +ₙ s-11) sh (XTHM {k = s-11} ix<s λ { (zero ∷ []) → s≤s (s≤s z≤n) ;
                                                                             (suc zero ∷ []) → s≤s (s≤s z≤n) })
                         s = _÷⟨ n-n ⟩ᵣ (scal 4.0) $
                             (scal $ p i1) +⟨ n-n ⟩ᵣ (scal $ p i2)
                             +⟨ n-n ⟩ᵣ (scal $ p i2) +⟨ n-n ⟩ᵣ (scal $ p i3)
                       in unscal s)



-- avgpool←{÷∘4{+/,⍵}⌺(2 2⍴2)⍤2⊢⍵}
avgpool1 : ∀ {s}
          → Ar Float 2 $ a→s (s→a s ×ₙ (scal 2))
          → Ar Float 2 s
avgpool1 {s} (imap p) = imap (λ iv → let
                         sh = (s→a s ×ₙ scal 2)
                         ix , ix<s = ix→a iv
                         bx = ix ×ₙ scal 2
                         ixs = ι (cst {s = 2 ∷ []} 2)
                         use-ixs i,pf = let
                            i , pf = i,pf
                            jx = bx +⟨ n-n ⟩ₙ i
                            in p (a→ix jx sh (XTHM ix<s pf))

                         s = _÷⟨ n-n ⟩ᵣ (scal 4.0) $ _+ᵣ_ / , use-ixs ¨ ixs
                        in unscal s)


-- multiconv←{(a ws bs)←⍵⋄bs{⍺+⍵ conv a}⍤(0,(⍴⍴a))⊢ws}
multiconv : ∀ {n m s sw so} → (a : Ar Float n s)
            →  (ws : Ar (Ar Float n sw) m so)
            →  (bs : Ar Float m so)
            →  {≥ : (s→a s) ≥a (s→a sw)}
            →  Ar (Ar Float n  (a→s $ ((s→a s -ₙ s→a sw) {≥}) +ₙ (scal 1))) m so
multiconv a ws bs {≥} = mapₐ₂ (λ b w → (scal b) +ᵣ conv w a {≥}) bs ws


--look-at-avgpl : ∀ {s} → (a : Ar Float 2 $ a→s (s→a s ×ₙ (scal 2))) → avgpool1 {s = s} a ≡ {!!}
--look-at-avgpl {x₁ ∷ x₂ ∷ []} (imap f) = {!!}
_̈₂_ : ∀ (a b : ℕ) → ℕ
a ̈₂ b = a + b

test-avgp = avgpool1 {s = 1 ∷ 1 ∷ []} (imap λ { (zero ∷ zero ∷ []) → 1.0 ;
                                                  (zero ∷ suc zero ∷ []) → 2.0 ;
                                                  (suc zero ∷ zero ∷ []) → 3.0 ;
                                                  (suc zero ∷ suc zero ∷ []) → 4.0 })
avgp-val = unimap test-avgp $ zero ∷ zero ∷ []


-- This should go into APL operators.
areplicate : ∀ {a}{X : Set a}{s} → (k : ℕ) → Ar X 1 s → Ar X _ _
areplicate k (imap f) = let
                          x = imap λ iv → imap {d = 1} {s = k ∷ []} λ _ → f iv
                        in , flatten x

test-repl = a→s $ areplicate 2 $ proj₁ ¨ ι (scal 5)



∸-monoˡ-< : ∀ {m n o} → m < n → o ≤ m → m ∸ o < n ∸ o
∸-monoˡ-< {o = zero}  m<n o≤m = m<n
∸-monoˡ-< {suc m} {o = suc o} (s≤s m<n) (s≤s o≤m) = ∸-monoˡ-< m<n o≤m


a+b-a≡a : ∀ {n} {s₁ : Vec ℕ n} {s : Ix 1 (n ∷ []) → ℕ}
             {jv : Ix 1 (n ∷ [])} →
           lookup (tabulate (λ i → s (i ∷ []) + lookup s₁ i))
           (ix-lookup jv zero)
           ∸ s jv
           ≡ lookup s₁ (ix-lookup jv zero)
a+b-a≡a {zero} {[]} {s} {x ∷ []} = magic-fin x
a+b-a≡a {suc n} {x ∷ s₁} {s} {I0} = m+n∸m≡n (s I0) x
a+b-a≡a {suc n} {x ∷ s₁} {s} {suc j ∷ []} = a+b-a≡a {s₁ = s₁} {s = λ { (j ∷ []) → s (suc j ∷ [])}} {jv = j ∷ []}


pre-pad : ∀ {a}{X : Set a}{n}{s₁ : Vec ℕ n}
        → (sh : Ar ℕ 1 (n ∷ []))
        → X
        → (a : Ar X n s₁)
        → Ar X n (a→s $ sh +ₙ ρ a)
pre-pad {s₁ = s₁} (imap s) e (imap f) = imap body
  where
    body : _
    body iv = let ix , ix<s = ix→a iv
              in case ix ≥a? (imap s) of λ where
                   (yes p) → let
                      fx = (ix -ₙ (imap s)) {≥ = p}
                      fv = a→ix fx (s→a s₁)
                                λ jv → a<b⇒b≡c⇒a<c
                                          (∸-monoˡ-< (ix<s jv) (p jv))
                                          (a+b-a≡a {s₁ = s₁} {s = s} {jv = jv})
                      in f (subst-ix (λ i → lookup∘tabulate _ i) fv)
                   (no ¬p) → e


_↑⟨_⟩_ : ∀ {a}{X : Set a}{n}{s : Vec ℕ n}
      → (sh : Ar ℕ 1 (n ∷ []))
      → X
      → (a : Ar X n s)
      → Ar X n (a→s sh)
_↑⟨_⟩_ {s = s} (imap sh) e (imap a) = imap body
  where
    body : _
    body iv = let ix , ix<s = ix→a iv
              in case ix <a? (ρ imap a) of λ where
                (yes p) → let
                            av = a→ix ix (ρ imap a) p
                          in a (subst-ix (λ i → lookup∘tabulate _ i) av)
                (no ¬p) → e


-- backin←{(d w in)←⍵⋄⊃+/,w{(⍴in)↑(-⍵+⍴d)↑⍺×d}¨⍳⍴w}
backin : ∀ {n s s₁} → (inp : Ar Float n s)
                     → (w : Ar Float n s₁)
                     → .{≥ : s→a s ≥a s→a s₁}
                     → (d : Ar Float n $ a→s $ (s→a s -ₙ s→a s₁) {≥} +ₙ scal 1)
                     → Ar Float n s
backin {n}{s}{s₁} inp w d = let
                                ixs = ι (ρ w)
                                use-ixs i,pf = let
                                  i , pf = i,pf
                                  iv = (a→ix i (ρ w) pf)
                                  wᵢ = (unimap w) (subst-ix (λ i → lookup∘tabulate _ i) iv)
                                  x = pre-pad i 0.0 (d ×ᵣ scal wᵢ)
                                  y = (ρ inp) ↑⟨ 0.0 ⟩ x
                                  in y
                                s = reduce-1d (, use-ixs ¨ ixs) _+ᵣ_ (cst 0.0)
                            in subst-ar (λ i → lookup∘tabulate _ i) s


{-
∇ backmulticonv ← {
  (d_out weights in bias) ← ⍵
  d_in ← +⌿d_out {backin ⍺ ⍵ in} ⍤((⍴⍴in), (⍴⍴in)) ⊢ weights
  d_w ← {⍵ conv in} ⍤(⍴⍴in) ⊢ d_out
  d_bias ← backbias ⍤(⍴⍴in) ⊢ d_out
  d_in d_w d_bias
}
∇
-}


{-
∀ {n m s sw so} → (a : Ar Float n s)
            →  (ws : Ar (Ar Float n sw) m so)
            →  (bs : Ar Float m so)
            →  {≥ : (s→a s) ≥a (s→a sw)}
            →  Ar (Ar Float n  (a→s $ ((s→a s -ₙ s→a sw) {≥}) +ₙ (scal 1))) m so -}

module not-need where 
  subst-vec : ∀ {a}{X : Set a}{n m}{xs : Vec X n}{x}{p : suc n ≡ suc m}
            → subst (Vec X) p (x ∷ xs) ≡ x ∷ subst (Vec X) (suc-injective p) xs
  subst-vec {p = refl} = refl

  {-
  ++-[] : ∀ {a}{X : Set a}{n}{x : Vec X n}
        → ∀ i → lookup (x ++ []) i ≡ lookup (subst (Vec X) (sym (n+0≡n n)) x) i
  ++-[] {n = zero} {[]} ()
  ++-[] {X = X} {n = suc n} {x ∷ xs} zero = sym
                                           $ cong (λ x → lookup x zero)
                                           $ subst-vec {X = X}{xs = xs}{x = x}{p = (sym (cong suc (n+0≡n n)))}  
  ++-[] {X = X}{n = suc n} {x ∷ xs} (suc i) = {!++-[] {X = X} {x = xs} i!}
  -}


hthm : ∀ {s w} → s ≥ w → s > 0 → w > 0 → s ∸ w + 1 ≤ s
hthm {suc s} {suc w} (s≤s s≥w) s>0 w>0 rewrite (+-comm (s ∸ w) 1) = s≤s (n∸m≤n w s)


helper : ∀ {n} {sI sw : Vec ℕ n}
       → s→a sI ≥a s→a sw
       → (cst 0) <a s→a sI
       → (cst 0) <a s→a sw
       → (iv : Ix 1 (n ∷ []))
       → lookup sI (ix-lookup iv zero) ≥
         lookup (tabulate (λ i → lookup sI i ∸ lookup sw i + 1))
         (ix-lookup iv zero)
helper {sI = sI} {sw} sI≥sw sI>0 sw>0 (x ∷ [])
       rewrite (lookup∘tabulate (λ i → lookup sI i ∸ lookup sw i + 1) x) =
       hthm (sI≥sw (x ∷ [])) (sI>0 (x ∷ [])) (sw>0 (x ∷ [])) 

shape-same : ∀ {n} {sI sw : Vec ℕ n}
           → s→a sI ≥a s→a sw
           → (cst 0) <a s→a sI
           → (cst 0) <a s→a sw
           → (i : Fin n)
           → lookup
             (tabulate
              (λ i₁ →
                 lookup sI i₁ ∸
                 lookup (tabulate (λ i₂ → lookup sI i₂ ∸ lookup sw i₂ + 1)) i₁
                 + 1))
             i
             ≡ lookup sw i
shape-same {suc n} {x ∷ sI} {y ∷ sw} I≥w I>0 w>0 zero =
  begin
    x ∸ (x ∸ y + 1) + 1 ≡⟨ sym $ +-∸-comm  {m = x} 1 {o = (x ∸ y + 1)}  (hthm (I≥w I0) (I>0 I0) (w>0 I0)) ⟩
    x + 1 ∸ (x ∸ y + 1) ≡⟨ cong (x + 1 ∸_) (sym $ +-∸-comm {m = x} 1 {o = y} (I≥w I0)) ⟩
    x + 1 ∸ (x + 1 ∸ y) ≡⟨ m∸[m∸n]≡n {m = x + 1} {n = y} (a≤b⇒b≡c⇒a≤c (≤-step $ I≥w I0) (+-comm 1 x)) ⟩
    y
  ∎
  where open ≡-Reasoning
shape-same {suc n} {x ∷ sI} {x₁ ∷ sw} I≥w I>0 w>0 (suc i) =
  shape-same {sI = sI} {sw = sw} (λ { (i ∷ []) → I≥w (suc i ∷ []) })
                                 (λ { (i ∷ []) → I>0 (suc i ∷ []) })
                                 (λ { (i ∷ []) → w>0 (suc i ∷ []) }) i


backmulticonv : ∀ {n m}{sI sw so}
              → (W : Ar (Ar Float n sw) m so)
              → (I : Ar Float n sI)
              → (B : Ar Float m so)
                -- We can get rid of these two expressions if we rewrite
                -- the convolution to accept s+1 ≥ w, and not s ≥ w.
              → {>I : (cst 0) <a s→a sI}
              → {>w : (cst 0) <a s→a sw}
              → {≥ : s→a sI ≥a s→a sw}
              → (δo : Ar (Ar Float n (a→s $ (s→a sI -ₙ s→a sw) {≥} +ₙ (scal 1))) m so)
              → (typeOf W) × (typeOf I) × (typeOf B)
backmulticonv {sI = sI} {sw} {so} W I B {sI>0} {sw>0} {sI≥sw} δo = let
    δI = reduce-1d (, mapₐ₂ (λ x y → backin I x {sI≥sw} y) W δo) _+ᵣ_ (cst 0.0)
    δW = (λ x → conv x I {s₁≥s = helper {sI = sI} {sw = sw} sI≥sw sI>0 sw>0}) ¨ δo
    δB = backbias ¨ δo
  in (imap (λ iv → subst-ar (shape-same {sI = sI} {sw = sw} sI≥sw sI>0 sw>0) ((unimap δW) iv)) ,
     δI ,
     imap (λ iv → unscal $ unimap δB iv))


instance
  auto≥ : ∀ {m n : ℕ} → {{_ : True (m ≥? n)}} → m ≥ n
  auto≥ {m} {n} {{c}} = toWitness c

  auto≥a : ∀ {d s}{p q : Ar ℕ d s} {{_ : True (p ≥a? q)}} → (p ≥a q)
  auto≥a {p = imap x} {imap x₁} ⦃ c ⦄ = toWitness c

  auto<a : ∀ {d s}{p q : Ar ℕ d s} {{_ : True (p <a? q)}} → (p <a q)
  auto<a {p = imap x} {imap x₁} ⦃ c ⦄ = toWitness c




test-zhang : (inp : Ar Float _ (28 ∷ 28 ∷ []))
           → (k₁ :  Ar Float _ (6 ∷ 5 ∷ 5 ∷ []))
           → (b₁ :  Ar Float _ (6 ∷ []))
           → (k₂ :  Ar Float _ (12 ∷ 6 ∷ 5 ∷ 5 ∷ []))
           → (b₂ :  Ar Float _ (12 ∷ []))
           → (fc : Ar Float _ (10 ∷ 12 ∷ 1 ∷ 4 ∷ 4 ∷ []))
           → (b :  Ar Float _ (10 ∷ []))
           → Ar Float _ (10 ∷ 1 ∷ 1 ∷ 1 ∷ 1 ∷ [])
test-zhang inp k₁ b₁ k₂ b₂ fc b = let
    c₁ = logistic ¨ multiconv inp (nest k₁) b₁ {auto≥a} --{λ { I0 → auto≥; I1 → auto≥ }}
    s₁ = avgpool1 {s = 12 ∷ 12 ∷ []} ¨ c₁
    c₂ = logistic ¨ multiconv (flatten s₁) (nest k₂) b₂ {auto≥a} -- {λ {I0 → auto≥; I1 → auto≥; I2 → auto≥}}
    s₂ = avgpool1 {s = 4 ∷ 4 ∷ []} ¨ (nest {s = _ ∷ _ ∷ []} $ flatten c₂)
    r = logistic ¨ multiconv (flatten s₂) (nest fc) b {auto≥a} -- {λ {I0 → auto≥; I1 → auto≥; I2 → auto≥; I3 → auto≥}}
  in flatten r



train-zhang :(inp : Ar Float _ (28 ∷ 28 ∷ []))
            → (k₁ :  Ar Float _ (6 ∷ 5 ∷ 5 ∷ []))
            → (b₁ :  Ar Float _ (6 ∷ []))
            → (k₂ :  Ar Float _ (12 ∷ 6 ∷ 5 ∷ 5 ∷ []))
            → (b₂ :  Ar Float _ (12 ∷ []))
            → (fc : Ar Float _ (10 ∷ 12 ∷ 1 ∷ 4 ∷ 4 ∷ []))
            → (b :  Ar Float _ (10 ∷ []))
            → (target : Ar Float _ (10 ∷ 1 ∷ 1 ∷ 1 ∷ 1 ∷ []))
            → typeOf k₁ × typeOf b₁ × typeOf k₂ × typeOf b₂ × typeOf fc × typeOf b × Scal Float
train-zhang inp k₁ b₁ k₂ b₂ fc b target = let
    c₁ = logistic ¨ multiconv inp (nest k₁) b₁ {auto≥a}
    s₁ = avgpool1 {s = 12 ∷ 12 ∷ []} ¨ c₁
    c₂ = logistic ¨ multiconv (flatten s₁) (nest k₂) b₂ {auto≥a}
    s₂ = avgpool1 {s = 4 ∷ 4 ∷ []} ¨ (nest {s = _ ∷ _ ∷ []} $ flatten c₂)
    o = flatten $ logistic ¨ multiconv (flatten s₂) (nest fc) b {auto≥a}

    δo = o -ᵣ target
    ε  = meansqerr (, o) (, target)
    δfc , δs₂ , δb  = backmulticonv (nest fc) (flatten s₂) b {>I = auto<a} {>w = auto<a} {≥ = auto≥a}
                                   (nest (blog δo o))
    δc₂ = backavgpool ¨ (nest {s = _ ∷ _ ∷ []} δs₂)
    δk₂ , δs₁ , δb₂ =  backmulticonv (nest k₂) (flatten s₁) b₂ {>I = auto<a} {>w = auto<a} {≥ = auto≥a}
                                    (nest (blog (flatten δc₂) (flatten c₂)))
    δc₁ = backavgpool ¨ (nest {s = _ ∷ []} δs₁)
    δk₁ , _ , δb₁ =  backmulticonv (nest k₁) inp b₁ {>I = auto<a} {>w = auto<a} {≥ = auto≥a}
                                  (nest (blog (flatten δc₁) (flatten c₁)))
    
  in (flatten δk₁) , δb₁ , (flatten δk₂) , δb₂ , (flatten δfc) , δb , ε
