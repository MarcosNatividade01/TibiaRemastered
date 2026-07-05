-- www.youtube.com/@fazendotibia/videos
-- Balanceamento solo: manter XP 10x e skills fisicos 3x enquanto rateUseStages = true.
-- rateExp/rateSkill em config.lua ficam como fallback quando stages forem desativados.

experienceStages = {
	{
		minlevel = 1,
		multiplier = 10,
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
		maxlevel = 60,
		multiplier = 10,
	},
	{
		minlevel = 61,
		maxlevel = 80,
		multiplier = 7,
	},
	{
		minlevel = 81,
		maxlevel = 100,
		multiplier = 5,
	},
	{
		minlevel = 101,
		maxlevel = 110,
		multiplier = 4,
	},
	{
		minlevel = 111,
		maxlevel = 125,
		multiplier = 3,
	},
	{
		minlevel = 126,
		multiplier = 2,
	},
}