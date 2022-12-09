" Vim syntax file
" Language:	Sapling Diff (context or unified)
" Maintainer:	Bram Moolenaar <Bram@vim.org>
"               Max Coplan <mchcopl@gmail.com>
"               Translations by Jakson Alves de Aquino.
" Last Change:	2022-12-08
" Forked from:	https://github.com/neovim/neovim/blob/ae5980ec797381cbaee7398a656bdb233f951981/runtime/syntax/diff.vim

" Quit when a (custom) syntax file was already loaded
if exists("b:current_syntax")
  finish
endif
scriptencoding utf-8

syn match diffOnly	"^SL: Only in .*"
syn match diffIdentical	"^SL: Files .* and .* are identical$"
syn match diffDiffer	"^SL: Files .* and .* differ$"
syn match diffBDiffer	"^SL: Binary files .* and .* differ$"
syn match diffIsA	"^SL: File .* is a .* while file .* is a .*"
syn match diffNoEOL	"^SL: \\ No newline at end of file .*"
syn match diffCommon	"^SL: Common subdirectories: .*"

" Disable the translations by setting diff_translations to zero.
if !exists("diff_translations") || diff_translations

" ca
syn match diffOnly	"^SL: Només a .*"
syn match diffIdentical	"^SL: Els fitxers .* i .* són idèntics$"
syn match diffDiffer	"^SL: Els fitxers .* i .* difereixen$"
syn match diffBDiffer	"^SL: Els fitxers .* i .* difereixen$"
syn match diffIsA	"^SL: El fitxer .* és un .* mentre que el fitxer .* és un .*"
syn match diffNoEOL	"^SL: \\ No hi ha cap caràcter de salt de línia al final del fitxer"
syn match diffCommon	"^SL: Subdirectoris comuns: .* i .*"

" cs
syn match diffOnly	"^SL: Pouze v .*"
syn match diffIdentical	"^SL: Soubory .* a .* jsou identické$"
syn match diffDiffer	"^SL: Soubory .* a .* jsou různé$"
syn match diffBDiffer	"^SL: Binární soubory .* a .* jsou rozdílné$"
syn match diffBDiffer	"^SL: Soubory .* a .* jsou různé$"
syn match diffIsA	"^SL: Soubor .* je .* pokud soubor .* je .*"
syn match diffNoEOL	"^SL: \\ Chybí znak konce řádku na konci souboru"
syn match diffCommon	"^SL: Společné podadresáře: .* a .*"

" da
syn match diffOnly	"^SL: Kun i .*"
syn match diffIdentical	"^SL: Filerne .* og .* er identiske$"
syn match diffDiffer	"^SL: Filerne .* og .* er forskellige$"
syn match diffBDiffer	"^SL: Binære filer .* og .* er forskellige$"
syn match diffIsA	"^SL: Filen .* er en .* mens filen .* er en .*"
syn match diffNoEOL	"^SL: \\ Intet linjeskift ved filafslutning"
syn match diffCommon	"^SL: Identiske underkataloger: .* og .*"

" de
syn match diffOnly	"^SL: Nur in .*"
syn match diffIdentical	"^SL: Dateien .* und .* sind identisch.$"
syn match diffDiffer	"^SL: Dateien .* und .* sind verschieden.$"
syn match diffBDiffer	"^SL: Binärdateien .* and .* sind verschieden.$"
syn match diffBDiffer	"^SL: Binärdateien .* und .* sind verschieden.$"
syn match diffIsA	"^SL: Datei .* ist ein .* während Datei .* ein .* ist.$"
syn match diffNoEOL	"^SL: \\ Kein Zeilenumbruch am Dateiende."
syn match diffCommon	"^SL: Gemeinsame Unterverzeichnisse: .* und .*.$"

" el
syn match diffOnly	"^SL: Μόνο στο .*"
syn match diffIdentical	"^SL: Τα αρχεία .* καί .* είναι πανομοιότυπα$"
syn match diffDiffer	"^SL: Τα αρχεία .* και .* διαφέρουν$"
syn match diffBDiffer	"^SL: Τα αρχεία .* και .* διαφέρουν$"
syn match diffIsA	"^SL: Το αρχείο .* είναι .* ενώ το αρχείο .* είναι .*"
syn match diffNoEOL	"^SL: \\ Δεν υπάρχει χαρακτήρας νέας γραμμής στο τέλος του αρχείου"
syn match diffCommon	"^SL: Οι υποκατάλογοι .* και .* είναι ταυτόσημοι$"

" eo
syn match diffOnly	"^SL: Nur en .*"
syn match diffIdentical	"^SL: Dosieroj .* kaj .* estas samaj$"
syn match diffDiffer	"^SL: Dosieroj .* kaj .* estas malsamaj$"
syn match diffBDiffer	"^SL: Dosieroj .* kaj .* estas malsamaj$"
syn match diffIsA	"^SL: Dosiero .* estas .*, dum dosiero .* estas .*"
syn match diffNoEOL	"^SL: \\ Mankas linifino ĉe fino de dosiero"
syn match diffCommon	"^SL: Komunaj subdosierujoj: .* kaj .*"

" es
syn match diffOnly	"^SL: Sólo en .*"
syn match diffIdentical	"^SL: Los ficheros .* y .* son idénticos$"
syn match diffDiffer	"^SL: Los ficheros .* y .* son distintos$"
syn match diffBDiffer	"^SL: Los ficheros binarios .* y .* son distintos$"
syn match diffIsA	"^SL: El fichero .* es un .* mientras que el .* es un .*"
syn match diffNoEOL	"^SL: \\ No hay ningún carácter de nueva línea al final del fichero"
syn match diffCommon	"^SL: Subdirectorios comunes: .* y .*"

" fi
syn match diffOnly	"^SL: Vain hakemistossa .*"
syn match diffIdentical	"^SL: Tiedostot .* ja .* ovat identtiset$"
syn match diffDiffer	"^SL: Tiedostot .* ja .* eroavat$"
syn match diffBDiffer	"^SL: Binääritiedostot .* ja .* eroavat$"
syn match diffIsA	"^SL: Tiedosto .* on .*, kun taas tiedosto .* on .*"
syn match diffNoEOL	"^SL: \\ Ei rivinvaihtoa tiedoston lopussa"
syn match diffCommon	"^SL: Yhteiset alihakemistot: .* ja .*"

" fr
syn match diffOnly	"^SL: Seulement dans .*"
syn match diffIdentical	"^SL: Les fichiers .* et .* sont identiques.*"
syn match diffDiffer	"^SL: Les fichiers .* et .* sont différents.*"
syn match diffBDiffer	"^SL: Les fichiers binaires .* et .* sont différents.*"
syn match diffIsA	"^SL: Le fichier .* est un .* alors que le fichier .* est un .*"
syn match diffNoEOL	"^SL: \\ Pas de fin de ligne à la fin du fichier.*"
syn match diffCommon	"^SL: Les sous-répertoires .* et .* sont identiques.*"

" ga
syn match diffOnly	"^SL: I .* amháin: .*"
syn match diffIdentical	"^SL: Is comhionann iad na comhaid .* agus .*"
syn match diffDiffer	"^SL: Tá difríocht idir na comhaid .* agus .*"
syn match diffBDiffer	"^SL: Tá difríocht idir na comhaid .* agus .*"
syn match diffIsA	"^SL: Tá comhad .* ina .* ach tá comhad .* ina .*"
syn match diffNoEOL	"^SL: \\ Gan líne nua ag an chomhadchríoch"
syn match diffCommon	"^SL: Fochomhadlanna i gcoitianta: .* agus .*"

" gl
syn match diffOnly	"^SL: Só en .*"
syn match diffIdentical	"^SL: Os ficheiros .* e .* son idénticos$"
syn match diffDiffer	"^SL: Os ficheiros .* e .* son diferentes$"
syn match diffBDiffer	"^SL: Os ficheiros binarios .* e .* son diferentes$"
syn match diffIsA	"^SL: O ficheiro .* é un .* mentres que o ficheiro .* é un .*"
syn match diffNoEOL	"^SL: \\ Non hai un salto de liña na fin da liña"
syn match diffCommon	"^SL: Subdirectorios comúns: .* e .*"

" he
" ^SL: .* are expansive patterns for long lines, so disabled unless we can match
" some specific hebrew chars
if search('\%u05d5\|\%u05d1', 'nw', '', 100)
  syn match diffOnly	"^SL: .*-ב קר אצמנ .*"
  syn match diffIdentical	"^SL: םיהז םניה .*-ו .* םיצבקה$"
  syn match diffDiffer	"^SL: הזמ הז םינוש `.*'-ו `.*' םיצבקה$"
  syn match diffBDiffer	"^SL: הזמ הז םינוש `.*'-ו `.*' םיירניב םיצבק$"
  syn match diffIsA	"^SL: .* .*-ל .* .* תוושהל ןתינ אל$"
  syn match diffNoEOL	"^SL: \\ ץבוקה ףוסב השד.-הרוש ות רס."
  syn match diffCommon	"^SL: .*-ו .* :תוהז תויקית-תת$"
endif

" hr
syn match diffOnly	"^SL: Samo u .*"
syn match diffIdentical	"^SL: Datoteke .* i .* su identične$"
syn match diffDiffer	"^SL: Datoteke .* i .* se razlikuju$"
syn match diffBDiffer	"^SL: Binarne datoteke .* i .* se razlikuju$"
syn match diffIsA	"^SL: Datoteka .* je .*, a datoteka .* je .*"
syn match diffNoEOL	"^SL: \\ Nema novog retka na kraju datoteke"
syn match diffCommon	"^SL: Uobičajeni poddirektoriji: .* i .*"

" hu
syn match diffOnly	"^SL: Csak .* -ben: .*"
syn match diffIdentical	"^SL: .* és .* fájlok azonosak$"
syn match diffDiffer	"^SL: A(z) .* és a(z) .* fájlok különböznek$"
syn match diffBDiffer	"^SL: A(z) .* és a(z) .* fájlok különböznek$"
syn match diffIsA	"^SL: A(z) .* fájl egy .*, viszont a(z) .* fájl egy .*"
syn match diffNoEOL	"^SL: \\ Nincs újsor a fájl végén"
syn match diffCommon	"^SL: Közös alkönyvtárak: .* és .*"

" id
syn match diffOnly	"^SL: Hanya dalam .*"
syn match diffIdentical	"^SL: File .* dan .* identik$"
syn match diffDiffer	"^SL: Berkas .* dan .* berbeda$"
syn match diffBDiffer	"^SL: File biner .* dan .* berbeda$"
syn match diffIsA	"^SL: File .* adalah .* sementara file .* adalah .*"
syn match diffNoEOL	"^SL: \\ Tidak ada baris-baru di akhir dari berkas"
syn match diffCommon	"^SL: Subdirektori sama: .* dan .*"

" it
syn match diffOnly	"^SL: Solo in .*"
syn match diffIdentical	"^SL: I file .* e .* sono identici$"
syn match diffDiffer	"^SL: I file .* e .* sono diversi$"
syn match diffBDiffer	"^SL: I file .* e .* sono diversi$"
syn match diffBDiffer	"^SL: I file binari .* e .* sono diversi$"
syn match diffIsA	"^SL: File .* è un .* mentre file .* è un .*"
syn match diffNoEOL	"^SL: \\ Manca newline alla fine del file"
syn match diffCommon	"^SL: Sottodirectory in comune: .* e .*"

" ja
syn match diffOnly	"^SL: .*だけに発見: .*"
syn match diffIdentical	"^SL: ファイル.*と.*は同一$"
syn match diffDiffer	"^SL: ファイル.*と.*は違います$"
syn match diffBDiffer	"^SL: バイナリー・ファイル.*と.*は違います$"
syn match diffIsA	"^SL: ファイル.*は.*、ファイル.*は.*"
syn match diffNoEOL	"^SL: \\ ファイル末尾に改行がありません"
syn match diffCommon	"^SL: 共通の下位ディレクトリー: .*と.*"

" ja DiffUtils 3.3
syn match diffOnly	"^SL: .* のみに存在: .*"
syn match diffIdentical	"^SL: ファイル .* と .* は同一です$"
syn match diffDiffer	"^SL: ファイル .* と .* は異なります$"
syn match diffBDiffer	"^SL: バイナリーファイル .* と.* は異なります$"
syn match diffIsA	"^SL: ファイル .* は .* です。一方、ファイル .* は .* です$"
syn match diffNoEOL	"^SL: \\ ファイル末尾に改行がありません"
syn match diffCommon	"^SL: 共通のサブディレクトリー: .* と .*"

" lv
syn match diffOnly	"^SL: Tikai iekš .*"
syn match diffIdentical	"^SL: Fails .* un .* ir identiski$"
syn match diffDiffer	"^SL: Faili .* un .* atšķiras$"
syn match diffBDiffer	"^SL: Faili .* un .* atšķiras$"
syn match diffBDiffer	"^SL: Binārie faili .* un .* atšķiras$"
syn match diffIsA	"^SL: Fails .* ir .* kamēr fails .* ir .*"
syn match diffNoEOL	"^SL: \\ Nav jaunu rindu faila beigās"
syn match diffCommon	"^SL: Kopējās apakšdirektorijas: .* un .*"

" ms
syn match diffOnly	"^SL: Hanya dalam .*"
syn match diffIdentical	"^SL: Fail .* dan .* adalah serupa$"
syn match diffDiffer	"^SL: Fail .* dan .* berbeza$"
syn match diffBDiffer	"^SL: Fail .* dan .* berbeza$"
syn match diffIsA	"^SL: Fail .* adalah .* manakala fail .* adalah .*"
syn match diffNoEOL	"^SL: \\ Tiada baris baru pada penghujung fail"
syn match diffCommon	"^SL: Subdirektori umum: .* dan .*"

" nl
syn match diffOnly	"^SL: Alleen in .*"
syn match diffIdentical	"^SL: Bestanden .* en .* zijn identiek$"
syn match diffDiffer	"^SL: Bestanden .* en .* zijn verschillend$"
syn match diffBDiffer	"^SL: Bestanden .* en .* zijn verschillend$"
syn match diffBDiffer	"^SL: Binaire bestanden .* en .* zijn verschillend$"
syn match diffIsA	"^SL: Bestand .* is een .* terwijl bestand .* een .* is$"
syn match diffNoEOL	"^SL: \\ Geen regeleindeteken (LF) aan einde van bestand"
syn match diffCommon	"^SL: Gemeenschappelijke submappen: .* en .*"

" pl
syn match diffOnly	"^SL: Tylko w .*"
syn match diffIdentical	"^SL: Pliki .* i .* są identyczne$"
syn match diffDiffer	"^SL: Pliki .* i .* różnią się$"
syn match diffBDiffer	"^SL: Pliki .* i .* różnią się$"
syn match diffBDiffer	"^SL: Binarne pliki .* i .* różnią się$"
syn match diffIsA	"^SL: Plik .* jest .*, podczas gdy plik .* jest .*"
syn match diffNoEOL	"^SL: \\ Brak znaku nowej linii na końcu pliku"
syn match diffCommon	"^SL: Wspólne podkatalogi: .* i .*"

" pt_BR
syn match diffOnly	"^SL: Somente em .*"
syn match diffOnly	"^SL: Apenas em .*"
syn match diffIdentical	"^SL: Os aquivos .* e .* são idênticos$"
syn match diffDiffer	"^SL: Os arquivos .* e .* são diferentes$"
syn match diffBDiffer	"^SL: Os arquivos binários .* e .* são diferentes$"
syn match diffIsA	"^SL: O arquivo .* é .* enquanto o arquivo .* é .*"
syn match diffNoEOL	"^SL: \\ Falta o caracter nova linha no final do arquivo"
syn match diffCommon	"^SL: Subdiretórios idênticos: .* e .*"

" ro
syn match diffOnly	"^SL: Doar în .*"
syn match diffIdentical	"^SL: Fişierele .* şi .* sunt identice$"
syn match diffDiffer	"^SL: Fişierele .* şi .* diferă$"
syn match diffBDiffer	"^SL: Fişierele binare .* şi .* diferă$"
syn match diffIsA	"^SL: Fişierul .* este un .* pe când fişierul .* este un .*.$"
syn match diffNoEOL	"^SL: \\ Nici un element de linie nouă la sfârşitul fişierului"
syn match diffCommon	"^SL: Subdirectoare comune: .* şi .*.$"

" ru
syn match diffOnly	"^SL: Только в .*"
syn match diffIdentical	"^SL: Файлы .* и .* идентичны$"
syn match diffDiffer	"^SL: Файлы .* и .* различаются$"
syn match diffBDiffer	"^SL: Файлы .* и .* различаются$"
syn match diffIsA	"^SL: Файл .* это .*, тогда как файл .* -- .*"
syn match diffNoEOL	"^SL: \\ В конце файла нет новой строки"
syn match diffCommon	"^SL: Общие подкаталоги: .* и .*"

" sr
syn match diffOnly	"^SL: Само у .*"
syn match diffIdentical	"^SL: Датотеке „.*“ и „.*“ се подударају$"
syn match diffDiffer	"^SL: Датотеке .* и .* различите$"
syn match diffBDiffer	"^SL: Бинарне датотеке .* и .* различите$"
syn match diffIsA	"^SL: Датотека „.*“ је „.*“ док је датотека „.*“ „.*“$"
syn match diffNoEOL	"^SL: \\ Без новог реда на крају датотеке"
syn match diffCommon	"^SL: Заједнички поддиректоријуми: .* и .*"

" sv
syn match diffOnly	"^SL: Endast i .*"
syn match diffIdentical	"^SL: Filerna .* och .* är lika$"
syn match diffDiffer	"^SL: Filerna .* och .* skiljer$"
syn match diffBDiffer	"^SL: Filerna .* och .* skiljer$"
syn match diffIsA	"^SL: Fil .* är en .* medan fil .* är en .*"
syn match diffBDiffer	"^SL: De binära filerna .* och .* skiljer$"
syn match diffIsA	"^SL: Filen .* är .* medan filen .* är .*"
syn match diffNoEOL	"^SL: \\ Ingen nyrad vid filslut"
syn match diffCommon	"^SL: Lika underkataloger: .* och .*"

" tr
syn match diffOnly	"^SL: Yalnızca .*'da: .*"
syn match diffIdentical	"^SL: .* ve .* dosyaları birbirinin aynı$"
syn match diffDiffer	"^SL: .* ve .* dosyaları birbirinden farklı$"
syn match diffBDiffer	"^SL: .* ve .* dosyaları birbirinden farklı$"
syn match diffBDiffer	"^SL: İkili .* ve .* birbirinden farklı$"
syn match diffIsA	"^SL: .* dosyası, bir .*, halbuki .* dosyası bir .*"
syn match diffNoEOL	"^SL: \\ Dosya sonunda yenisatır yok."
syn match diffCommon	"^SL: Ortak alt dizinler: .* ve .*"

" uk
syn match diffOnly	"^SL: Лише у .*"
syn match diffIdentical	"^SL: Файли .* та .* ідентичні$"
syn match diffDiffer	"^SL: Файли .* та .* відрізняються$"
syn match diffBDiffer	"^SL: Файли .* та .* відрізняються$"
syn match diffBDiffer	"^SL: Двійкові файли .* та .* відрізняються$"
syn match diffIsA	"^SL: Файл .* це .*, тоді як файл .* -- .*"
syn match diffNoEOL	"^SL: \\ Наприкінці файлу немає нового рядка"
syn match diffCommon	"^SL: Спільні підкаталоги: .* та .*"

" vi
syn match diffOnly	"^SL: Chỉ trong .*"
syn match diffIdentical	"^SL: Hai tập tin .* và .* là bằng nhau.$"
syn match diffIdentical	"^SL: Cả .* và .* là cùng một tập tin$"
syn match diffDiffer	"^SL: Hai tập tin .* và .* là khác nhau.$"
syn match diffBDiffer	"^SL: Hai tập tin nhị phân .* và .* khác nhau$"
syn match diffIsA	"^SL: Tập tin .* là một .* trong khi tập tin .* là một .*.$"
syn match diffBDiffer	"^SL: Hai tập tin .* và .* là khác nhau.$"
syn match diffIsA	"^SL: Tập tin .* là một .* còn tập tin .* là một .*.$"
syn match diffNoEOL	"^SL: \\ Không có ký tự dòng mới tại kêt thức tập tin."
syn match diffCommon	"^SL: Thư mục con chung: .* và .*"

" zh_CN
syn match diffOnly	"^SL: 只在 .* 存在：.*"
syn match diffIdentical	"^SL: 檔案 .* 和 .* 相同$"
syn match diffDiffer	"^SL: 文件 .* 和 .* 不同$"
syn match diffBDiffer	"^SL: 文件 .* 和 .* 不同$"
syn match diffIsA	"^SL: 文件 .* 是.*而文件 .* 是.*"
syn match diffNoEOL	"^SL: \\ 文件尾没有 newline 字符"
syn match diffCommon	"^SL: .* 和 .* 有共同的子目录$"

" zh_TW
syn match diffOnly	"^SL: 只在 .* 存在：.*"
syn match diffIdentical	"^SL: 檔案 .* 和 .* 相同$"
syn match diffDiffer	"^SL: 檔案 .* 與 .* 不同$"
syn match diffBDiffer	"^SL: 二元碼檔 .* 與 .* 不同$"
syn match diffIsA	"^SL: 檔案 .* 是.*而檔案 .* 是.*"
syn match diffNoEOL	"^SL: \\ 檔案末沒有 newline 字元"
syn match diffCommon	"^SL: .* 和 .* 有共同的副目錄$"

endif


syn match diffRemoved	"^SL: -.*"
syn match diffRemoved	"^SL: <.*"
syn match diffAdded	"^SL: +.*"
syn match diffAdded	"^SL: >.*"
syn match diffChanged	"^SL: ! .*"

syn match diffSubname	" @@..*"ms=s+3 contained
syn match diffLine	"^SL: @.*" contains=diffSubname
syn match diffLine	"^SL: \<\d\+\>.*"
syn match diffLine	"^SL: \*\*\*\*.*"
syn match diffLine	"^SL: ---$"

" Some versions of diff have lines like "#c#" and "#d#" (where # is a number)
syn match diffLine	"^SL: \d\+\(,\d\+\)\=[cda]\d\+\>.*"

syn match diffFile	"^SL: diff\>.*"
syn match diffFile	"^SL: Index: .*"
syn match diffFile	"^SL: ==== .*"

if search('^SL: @@ -\S\+ +\S\+ @@', 'nw', '', 100)
  " unified
  syn match diffOldFile	"^SL: --- .*"
  syn match diffNewFile	"^SL: +++ .*"
else
  " context / old style
  syn match diffOldFile	"^SL: \*\*\* .*"
  syn match diffNewFile	"^SL: --- .*"
endif

" Used by git
syn match diffIndexLine	"^SL: index \x\x\x\x.*"

syn match diffComment	"^SL: #.*"

" Define the default highlighting.
" Only used when an item doesn't have highlighting yet
hi def link diffOldFile		diffFile
hi def link diffNewFile		diffFile
hi def link diffIndexLine	PreProc
hi def link diffFile		Type
hi def link diffOnly		Constant
hi def link diffIdentical	Constant
hi def link diffDiffer		Constant
hi def link diffBDiffer		Constant
hi def link diffIsA		Constant
hi def link diffNoEOL		Constant
hi def link diffCommon		Constant
hi def link diffRemoved		Special
hi def link diffChanged		PreProc
hi def link diffAdded		Identifier
hi def link diffLine		Statement
hi def link diffSubname		PreProc
hi def link diffComment		Comment

let b:current_syntax = "diff"

" vim: ts=8 sw=2
