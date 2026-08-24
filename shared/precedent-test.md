# Test dostupnosti precedentu

> **Rozsah:** Sdílený kontrakt pluginu `sagittaras`. Test, kterým `triage-issue`
> a `plan-milestone` rozhodují, jestli položka (existující issue nebo kandidát
> z backlogu) rozšiřuje existující vzor v kódu, nebo vyžaduje novou
> architekturu. Otevři ho vždy, než tenhle test provedeš — dvě kopie stejného
> pravidla se dřív nebo později rozejdou.

Hledej `Glob`/`Grep`/`Read` existující soubor, skill, modul nebo vzor, který
popsaný požadavek **rozšiřuje**, ne jen tematicky souvisí.

Test, který rozhoduje: *jde požadavek splnit úpravou nebo rozšířením tohohle
konkrétního souboru/vzoru, aniž by bylo nejdřív nutné vymyslet architekturu,
která v repozitáři ještě neexistuje?* Odpověď ano/ne určuje další krok.

Nehledej vzor jen proto, aby se našel — vzdálená podobnost („taky se to týká
skillů") nestačí, precedent musí být to konkrétní místo, které se rozšiřuje.
