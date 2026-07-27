local spell = Spell("instant")

function spell.onCastSpell(creature, variant)
	return creature:conjureItem(3147, 3172, 3)
end

spell:name("Poison Field Rune")
spell:words("adevo grav pox")
spell:group("support")
spell:vocation("druid;true", "elder druid;true", "sorcerer;true", "master sorcerer;true")
spell:cooldown(Remastered.Balance.applyPlayerSpellCooldown(2 * 1000))
spell:groupCooldown(Remastered.Balance.applyPlayerSpellCooldowns(2 * 1000))
spell:level(14)
spell:mana(200)
spell:soul(1)
spell:isAggressive(false)

spell:register()
