# Nomogrammi ospedalieri di Barber–Johnson

Disponibile nel ramo di sviluppo Rj/Rjp. Non richiede pacchetti R opzionali né un’installazione Python. Descrive l’utilizzo dei posti letto ospedalieri, non la qualità clinica, l’efficienza corretta per case-mix o il fabbisogno futuro.

## Struttura del dataset

**Una riga rappresenta un reparto/struttura in un periodo definito.** La coppia
`unit` + `period` deve essere univoca. Aggregare esplicitamente eventuali record
di dettaglio prima della chiamata. Confrontare ambiti assistenziali omogenei;
separare ricovero ordinario e attività diurna. Dichiarare se i trasferimenti
sono conteggiati come uscite del reparto, mantenendo coerenti giornate e capacità.

CSV sintetico: `examples/data/10_barber_johnson_hospital.csv`, tre reparti per
quattro trimestri reali del 2025, con variazione della capacità. Lo script
`10_barber_johnson.R` contiene gli stessi dati e funziona anche senza file.
In Rjp selezionare tutte le colonne usate quando si passa il dataset corrente.
Gli argomenti permettono di associare nomi diversi: non occorre rinominare i dati.

| Argomento / colonna dell'esempio | Significato e unità | Requisito |
| --- | --- | --- |
| `unit='unit'` | Identificativo reparto/struttura | Obbligatorio, non mancante |
| `period='period'` | Etichetta del periodo, es. 2025 Q1 | Obbligatoria; univoca nel reparto |
| `period_days='period_days'` | Durata effettiva in giorni | Colonna numerica positiva o costante positiva comune a tutte le righe |
| `beds='beds'` | Posti letto medi effettivamente disponibili | Positivi; usati se non si passa available_bed_days |
| `available_bed_days=NULL` | Somma giornaliera dei letti disponibili, in giornate-letto | Preferibile se la capacità varia; positiva; sostituisce beds × giorni |
| `occupied_bed_days='occupied_bed_days'` | Giornate di degenza occupate nel periodo | Dati grezzi; non negative, non superiori alle giornate disponibili |
| `discharges='discharges'` | Uscite concluse nel periodo, inclusi decessi secondo la definizione adottata | Dati grezzi; conteggi interi positivi |
| `order='period_order'` | Posizione cronologica numerica | Obbligatoria per traiettorie, univoca nel reparto |
| `facet='unit'` | Raggruppamento dei pannelli | Facoltativo; default reparto, massimo 12 pannelli |
| `group='clinical_area'` | Raggruppamento per colore/legenda | Facoltativo; default reparto; usare unit per selezionare le traiettorie dei singoli reparti |
| `toi='toi'`, `alos='alos'` | TOI e degenza media del nomogramma già calcolati, in giorni | input_mode='toi_alos'; TOI ≥ 0 e ALOS > 0 |
| `bor='bor'` | Occupazione come proporzione | input_mode='alos_bor'; 0 < BOR ≤ 1, non percentuale 0–100 |

`input_mode='raw'` è il default e usa capacità, giornate occupate e uscite.
Non cambia modalità in base alla presenza di altre colonne. Le alternative
esplicite sono `'toi_alos'` e `'alos_bor'`, con indicatori definiti coerentemente.
Da due indicatori non si ricavano i posti letto assoluti: con dati precalcolati,
`size_by_beds=TRUE` richiede una vera colonna beds, senza inventare capacità.

Le righe con input richiesti mancanti vengono escluse e restituite con numero
di riga da 1. Valori finiti non validi, duplicati o capacità incoerenti producono
errore. Massimo 2.000 righe complete per risultato. data e dataext non cambiano.

## Formule e riferimento temporale

T = giorni del periodo; C = giornate-letto disponibili; O = giornate occupate;
D = dimissioni/uscite; B = C/T = letti medi disponibili. A capacità costante,
C = B × T.

| Indicatore | Formula | Unità |
| --- | --- | --- |
| Degenza media del nomogramma, L | O / D | giorni |
| Intervallo di turnover, I | (C − O) / D | giorni |
| Occupazione, p | O / C = L / (L + I) | proporzione, visualizzata come 100p% |
| Rotazione nel periodo, R | D / B = T / (L + I) | uscite per letto medio nei T giorni |
| Rotazione sul riferimento T₀, R₀ | R × T₀/T = T₀ / (L + I) | uscite per letto sulla base temporale scelta |

Esempio: 10 letti medi, 90 giorni, C=900, O=720, D=90: L=8 giorni, I=2 giorni,
occupazione=80%, R=9 nel trimestre e R₀=36,5 su 365 giorni. L'annualizzazione
è un cambio della base di un tasso, non una previsione. Tabella e dettaglio
dei punti conservano sia la rotazione osservata sia quella di riferimento.
Usare la durata effettiva, inclusi anni bisestili. L'occupazione aggregata è
somma(O)/somma(C), non la media semplice delle percentuali dei reparti:
aggregare intenzionalmente i dati grezzi.

**ALOS qui è giornate del periodo / uscite del periodo.** Può differire dalla
durata media individuale dei ricoveri conclusi nello stesso periodo a causa
delle degenze che ne attraversano i confini. Non mescolare definizioni e
aspettarsi identità esatte. Il TOI è un indicatore aggregato della capacità:
non misura direttamente il tempo di pulizia/preparazione del letto.

Equazioni delle linee/curve:

- Raggi di occupazione TOI–ALOS: L = p I / (1 − p).
- Rette di rotazione TOI–ALOS: L = T₀/R₀ − I.
- Curve di occupazione TOI–BTO: R₀ = T₀(1 − p)/I, per I > 0.
- Curve ad ALOS costante TOI–BTO: R₀ = T₀/(L + I).

Per I=0 il punto a occupazione completa mantiene la propria rotazione finita;
la curva singolare non viene calcolata in zero. Il trimestre non viene
trattato impropriamente come un anno di 365 giorni.

## Quattro presentazioni

- `view='toi_alos'`: nomogramma classico con raggi di occupazione e rette di rotazione.
- `view='toi_bto'`: TOI contro BTO sulla base temporale scelta, con curve BOR e ALOS.
- `view='trajectory'`: posizioni TOI–ALOS connesse in ordine numerico esplicito
  per reparto; le frecce indicano sequenza, non causalità. Una connessione può
  attraversare un periodo mancante perché le righe incomplete sono escluse.
- `view='faceted'`: pannelli verticali separati con gli stessi limiti degli assi.
  L'altezza è per pannello, non quella totale della figura.

## Chiamata e personalizzazione

```r
report <- mzrjShowBarberJohnson(
    data, view='trajectory', input_mode='raw',
    unit='reparto', period='trimestre', period_days='giorni',
    available_bed_days='giornate_disponibili',
    occupied_bed_days='giornate_occupate', discharges='uscite',
    order='ordine_trimestre', group='reparto', turnover_days=365,
    scenarios=list(
        list(label='Intervallo scelto localmente', bor=c(.75,.85), toi=c(1,3)),
        list(label='Soglia di confronto', bor=.90)),
    width=800, height=400, result_type='html', name='nomogramma_ospedaliero')
```

`turnover_days=365` stabilisce la base di confronto della rotazione. Le famiglie
di riferimenti sono configurabili: `occupancy_lines` (proporzioni),
`turnover_lines` (rotazione sulla base scelta), `alos_lines` (giorni).
numeric(0) nasconde la famiglia; massimo 12 valori per famiglia.
`max_toi`, `max_alos`, `max_bto` fissano i limiti, altrimenti ricavati dai dati.
I punti esterni sono tagliati e conteggiati nel resoconto.
`size_by_beds=FALSE`: con TRUE la dimensione segue la radice della capacità,
con raggio minimo leggibile. `point_labels=FALSE` evita affollamento;
TRUE aggiunge reparto o periodo, con possibile sovrapposizione nei dati densi.
I valori sono comunque leggibili selezionando i punti.

`scenarios=NULL`: nessuna area obiettivo predefinita. Fino a sei liste R con nomi con
`label` univoca, `bor` come soglia singola o intervallo c(min,max), e limiti
facoltativi `toi`/`alos` in giorni. BOR strettamente tra 0 e 1. La soglia singola
traccia una linea; gli intervalli producono intersezioni leggermente colorate.
Sono riferimenti scelti dall'utente, non categorie automatiche di efficienza.
La legenda mostra/nasconde gruppi e scenari senza ricalcolare i dati. Le note
riportano i valori; l'esportazione Svg riporta anche la visibilità della legenda.

Passaggio del puntatore/focus: lettura dei quattro indicatori. Click/Invio:
selezione fissata con proiezioni; Escape: annullamento. Lo slider condiviso
ingrandisce figura e area Results, senza cambiare assi o indicatori. Reset
ripristina dimensione e selezione, conservando le scelte di visibilità.

`width=NULL`, `height=NULL`: valori del popup, poi default Rj (400 × 300 pixel). Gli argomenti
espliciti prevalgono. Nei pannelli l'altezza totale è altezza × numero pannelli.
`result_type`: html, svg vettoriale, image catturata. Svg/Image nativi senza
accordion/zoom Html, con ridimensionamento jamovi. Rilasciare il gancio di una
Image aggiorna soltanto le dimensioni e il raster di quella figura: non esegue
R, non riavvia le catture e conserva le altre figure e la tabella. La
dimensione di base resta invariata anche dopo trascinamenti ripetuti.
Per Html: `accordion=TRUE`,
`expanded=TRUE`, `accordion_type='line'` oppure 'bordered'. `tables=TRUE` aggiunge
la tabella nativa. Restituisce invisibilmente una lista con `indicators` (data frame R),
`excluded_rows` (numeri di riga da 1), `outside`, `turnover_days` e `scenarios`. Lo script 10 dimostra tutte e quattro le viste sullo stesso dataset.

## Letteratura e interpretazione attuale

Conserviamo la costruzione classica e contestualizziamo la lettura: capacità
realmente utilizzabile, tipologia assistenziale, casistica e picchi giornalieri
contano. OECD 2025 esplicita l'assenza di consenso su un'occupazione ottimale
universale. L'85% non diventa automaticamente uno standard clinico generale;
le soglie locali richiedono una motivazione. Dal solo nomogramma non si
stimano riserva latente, adeguatezza del personale, giornate evitabili o
fabbisogno futuro di letti.

Bibliografia (anno di pubblicazione distinto dal periodo dei dati):

1. Barber B, Johnson D. *The Presentation of Acute Hospital In-patient Statistics*.
   Hospital and Health Services Review, 1973. Costruzione storica; testo originale
   integrale non esaminato.
2. Pulgar Perera VA, Paniagua Tejo MT, Sañudo García S. *Barber and Johnson diagram
   and latent reserve as tools to optimise the management of hospital beds*.
   J Healthc Qual Res. 2019;34(3):124–130.
   https://doi.org/10.1016/j.jhqr.2019.02.001 — abstract esaminato; l'helper non
   implementa uno stimatore della riserva latente.
3. OECD. *Health at a Glance 2025*, Hospital beds and occupancy.
   https://www.oecd.org/content/dam/oecd/en/publications/reports/2025/11/health-at-a-glance-2025_a894f72e/8f9e3f98-en.pdf
4. WHO Europe. *Bed occupancy rate (%), acute care hospitals only*.
   https://gateway.euro.who.int/en/indicators/hfa_542-6210-bed-occupancy-rate-acute-care-hospitals-only/
5. Tamarina FA, Suswojo H, Absor S. *Efficiency of Inpatient Care Services at
   Surabaya Islamic Hospital in 2022–2023 Using the Barber-Johnson Approach*.
   Qanun Medika. 2026;10(1). https://doi.org/10.3651/jqm.v10i01.27393
   Applicazione locale descrittiva recente, non validazione di soglie universali.

Il PDF portuale di Raffaele (2014) è supporto all'analogia
matematica: definizioni e soglie portuali non vengono trasferite all'ospedale.
Tutti i dati ospedalieri forniti sono sintetici.

### Cattura di più immagini e recupero

Se più Image appartengono alla stessa analisi, il bridge invia una PNG per volta e attende la sostituzione del relativo risultato prima di inviare la successiva. Non accumula grandi payload nell'opzione. Passare a Html o rieseguire scarta le catture obsolete; una conferma mancante produce un errore visibile. I contenitori Svg nativi consentono tutta la dimensione scelta con il gancio jamovi, senza ritagli interni.



### Dimensioni e compatibilità Linux

Su alcune installazioni Linux il gancio nativo Svg/Image è in basso a sinistra e può non rispondere. Usare `width` e `height` della funzione oppure i valori globali del PopUp quando gli argomenti sono omessi. Gli argomenti espliciti prevalgono sul PopUp. Lo esempio 10 specifica già le dimensioni: ometterle per provare i valori globali. Il ridimensionamento Image conserva le altre figure e tabelle senza rieseguire R.

Il manutentore ha riscontrato il gancio Image in basso a sinistra bloccato anche nei grafici di moduli di altri autori nello stesso ambiente Ubuntu. Questo aggiornamento non dichiara di correggere tale comportamento nativo condiviso.
