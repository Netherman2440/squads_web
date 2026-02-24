Aktualnie mamy już w db miejsce na pozycje graczy - chce teraz zhardkodować input do tych miejsc.

Bazowo ma to być do wyboru tylko opcja z enuma 'goalkeeper', defender, midfielder i attacker (w kodzie: PlayerPosition.midfielder, w storage/db pozostaje legacy 'middlefielder').

Bazowo gracz nie ma pozycji.

W ui wyświetlamy polski odpowiednik tego enuma.

Trzeba to wziąć pod uwagę przy create player - w samym drafcie już chyba pozycje są brane pod uwagę
