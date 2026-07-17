# Targuna Manual GUI Checklist

Sandbox only. Do not use production, real accounts, or real characters.

Account:
- Login: `targuna_test@remastered.local`
- Password: `TargunaTest123`
- Character: `Targuna Tester`

Start:
- Run `Start-Targuna-Test.bat`
- Run `Start-Targuna-Client.bat`

Initial position:
- `50016,50023,7`

Checklist:

- [ ] Login
- [ ] Entrada no mundo
- [ ] Movimento
- [ ] Floors
- [ ] NPC
- [ ] Diálogo
- [ ] Monstro
- [ ] Combate
- [ ] Morte
- [ ] Loot
- [ ] Teleport
- [ ] Herald
- [ ] Sem crash

Suggested order:
1. Login with `Targuna Tester`.
2. Walk north, south, east, and west.
3. Validate a nearby floor transition in the Hub.
4. Talk to Captain Indigo: `hi`, `trade`, `bye`.
5. Move to Aragonia through the intended route or sandbox positioning and test `Freshwater Turtle` first.
6. Attack, kill, open corpse, and check loot.
7. Validate the Matilda/Aragonia teleport path.
8. Only after the previous checks pass, test Herald of Fire lever/trigger.

Notes:
- Save screenshots and observations under `UpstreamTesting/TargunaRuntime/Logs/ManualValidation/`.
- Keep Targuna as `PARTIALLY_READY` until all boxes are validated.
