local spell = Spell("instant")

function spell.onCastSpell(creature, variant)
	return creature:conjureItem(3147, 3200, 6)
end

spell:name("Explosion Rune")
spell:words("adevo mas hur")
spell:group("support")
spell:vocation("druid;true", "elder druid;true", "sorcerer;true", "master sorcerer;true")
spell:cooldown(Remastered.Balance.applyPlayerSpellCooldown(2 * 1000))
spell:groupCooldown(Remastered.Balance.applyPlayerSpellCooldowns(2 * 1000))
spell:level(31)
spell:mana(570)
spell:soul(4)
spell:isAggressive(false)

spell:register()
