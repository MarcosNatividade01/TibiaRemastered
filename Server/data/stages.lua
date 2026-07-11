-- www.youtube.com/@fazendotibia/videos
-- Balanceamento de teste: XP 8x, skills fisicos 3x e magic level 3x.
-- rateExp/rateSkill em config.lua ficam como fallback quando stages forem desativados.

experienceStages = {
	{
		minlevel = 1,
		multiplier = 8,
	},
}

skillsStages = {
	{
		minlevel = 0,
		multiplier = 3,
	},
}

magicLevelStages = {
	{
		minlevel = 0,
		multiplier = 3,
	},
}
