## Motore della campagna: stato, creazione dell'equipaggio, turno di campagna completo e sequenza post-battaglia.
## Nessuna dipendenza dall'interfaccia: tutto passa per lo stato (Dictionary salvabile in JSON) e per il diario.
class_name Campagna
extends RefCounted

const VERSIONE := 1

## Sinonimi degli id di specie usati in file diversi dei dati.
const ALIAS_SPECIE := {"senzanima": "soulless", "precursore": "precursor", "ingegnere": "engineer",
	"robot": "bot", "ferale": "feral", "umani": "umano", "bot_d_assalto": "bot_assalto"}

## Fasi del turno nell'ordine del regolamento (p.68).
const FASI := ["viaggio", "mantenimento", "incarichi", "lavori", "equipaggiamento", "dicerie", "scelta_battaglia",
	"battaglia", "dopo_battaglia", "acquisti", "eventi", "fine"]
const NOMI_FASI := {"viaggio": "Viaggio", "mantenimento": "Mantenimento e nave", "incarichi": "Incarichi dell'equipaggio",
	"lavori": "Offerte di lavoro", "equipaggiamento": "Assegnare l'equipaggiamento", "dicerie": "Dicerie e missioni",
	"scelta_battaglia": "Scegliere la battaglia", "battaglia": "Battaglia", "dopo_battaglia": "Dopo la battaglia",
	"acquisti": "Acquisti e addestramento", "eventi": "Eventi", "fine": "Fine del turno"}

var s: Dictionary = {}
var dadi: Dadi

func _init(stato: Dictionary = {}, seme: int = 0) -> void:
	Dati.carica()
	dadi = Dadi.new(seme)
	if not stato.is_empty():
		s = stato
		if s.has("dadi"):
			dadi.ripristina(s["dadi"])

func salva() -> Dictionary:
	s["dadi"] = dadi.stato()
	s["salvato"] = Time.get_datetime_string_from_system()
	return s

## ===================== diario =====================

func scrivi(testo: String, tipo := "") -> void:
	if not s.has("diario"):
		s["diario"] = []
	s["diario"].append({"turno": int(s.get("turno", 0)), "testo": testo, "tipo": tipo})
	if s["diario"].size() > 3000:
		s["diario"] = s["diario"].slice(s["diario"].size() - 3000)

func diario_recente(n := 40) -> Array:
	var d: Array = s.get("diario", [])
	return d.slice(max(0, d.size() - n))

## ===================== nuova campagna =====================

static func id_specie(id: String) -> String:
	return ALIAS_SPECIE.get(id, id)

func nuova(opzioni: Dictionary) -> void:
	s = {
		"versione": VERSIONE, "codice": nuovo_codice(), "nome": str(opzioni.get("nome", "Equipaggio senza nome")), "turno": 0, "fase": "creazione",
		"crediti": 0, "punti_storia": 0, "dicerie": 0, "dicerie_missione": 0, "missione": {},
		"difficolta": str(opzioni.get("difficolta", "normale")), "dimensione": int(opzioni.get("dimensione", 6)),
		"opzioni": {"eventi_battaglia": bool(opzioni.get("eventi_battaglia", true)), "storia": bool(opzioni.get("storia", false)),
			"zone": bool(opzioni.get("zone", true)), "celle_tavolo": int(opzioni.get("tavolo", 24))},
		"storia": {"attiva": bool(opzioni.get("storia", false)), "orologio": 5, "evento": 0, "in_corso": false},
		"nave": {}, "equipaggio": [], "deposito": [], "rivali": [], "patroni": [], "offerte": [], "lavoro": {},
		"mondo": {}, "mondi_visitati": 0, "pianeti_invasi": [], "licenze": [], "diario": [], "incarichi": {},
		"scelte": [], "statistiche": {"battaglie": 0, "vittorie": 0, "morti": 0, "turni": 0},
		"zona_rossa": {"licenza": false}, "battaglia": {}, "esito": {}, "flag": {},
	}
	scrivi("Nasce l'equipaggio «%s»." % s["nome"], "titolo")

func nuovo_codice() -> String:
	var lettere := "ABCDEFGHJKLMNPQRSTUVWXYZ"
	var r := ""
	for i in 6:
		r += lettere[dadi.d(lettere.length()) - 1]
	return r

## Tira il tipo di un nuovo personaggio (tabella Tipo di equipaggio e sottotabelle).
func tira_specie() -> String:
	var sp := Dati.f("specie")
	var r := dadi.su_tabella(sp.get("tipo_equipaggio", {}))
	var tipo := str(r["riga"].get("tipo", r["riga"].get("specie", "umano")))
	if tipo == "alieno_primario":
		tipo = str(dadi.su_tabella(sp.get("alieni_primari", {}))["riga"].get("specie", "engineer"))
	elif tipo == "strano" or tipo == "personaggio_strano":
		tipo = str(dadi.su_tabella(sp.get("personaggi_strani", {}))["riga"].get("specie", "umano"))
	tipo = id_specie(tipo)
	if Dati.specie(tipo).is_empty():
		tipo = "umano"
	return tipo

func nome_casuale(altri: Array = []) -> String:
	var usati := altri.duplicate()
	for p in s.get("equipaggio", []):
		usati.append(p.get("nome"))
	var nomi: Array = Dati.f("creazione").get("nomi", ["Ada"])
	for i in 30:
		var n: String = dadi.scegli(nomi)
		if not n in usati:
			return n
	return "%s %d" % [dadi.scegli(nomi), dadi.d(99)]

## Crea un personaggio: specie a scelta (o tirata) e tiri su Background, Motivazione e Classe.
## scelte = {"background": indice_riga, "motivazione": ..., "classe": ...} per scegliere invece di tirare.
func crea_personaggio(id_sp := "", nome := "", scelte := {}, applica_risorse := true) -> Dictionary:
	if id_sp == "":
		id_sp = tira_specie()
	if nome == "":
		nome = nome_casuale()
	var pg := Personaggio.da_specie(id_sp, nome)
	if Personaggio.usa_tabelle(pg):
		var b = Personaggio.bonus(pg, "tiri_background", 1)
		for i in int(b):
			_tabella_creazione(pg, "background", scelte.get("background", -1) if i == 0 else -1, applica_risorse)
		_tabella_creazione(pg, "motivazione", scelte.get("motivazione", -1), applica_risorse)
		_tabella_creazione(pg, "classe", scelte.get("classe", -1), applica_risorse)
	var bon: Dictionary = Personaggio.info_specie(pg).get("bonus", {})
	if applica_risorse:
		for k in ["punti_storia", "dicerie"]:
			if bon.has(k) and (bon[k] is int or bon[k] is float):
				s[k] = int(s.get(k, 0)) + int(bon[k])
	return pg

func _riga_per_nome_en(tab: Dictionary, en: String) -> int:
	var righe: Array = tab.get("righe", [])
	for i in righe.size():
		if str(righe[i].get("en", "")).to_lower().begins_with(en.to_lower()):
			return i
	return -1

func _tabella_creazione(pg: Dictionary, quale: String, indice := -1, applica_risorse := true) -> void:
	var tab: Dictionary = Dati.f("creazione").get(quale, {})
	var righe: Array = tab.get("righe", [])
	if righe.is_empty():
		return
	var fisso = Personaggio.bonus(pg, quale + "_fisso" if quale != "motivazione" else "motivazione_fissa")
	if fisso != null and indice < 0:
		indice = _riga_per_nome_en(tab, str(fisso))
	var riga: Dictionary
	if indice >= 0 and indice < righe.size():
		riga = righe[indice]
	else:
		riga = dadi.su_tabella(tab)["riga"]
	if quale == "classe":
		var sost = Personaggio.bonus(pg, "sostituzioni_classe", {})
		if sost is Dictionary and sost.has(str(riga.get("en", ""))):
			var j := _riga_per_nome_en(tab, str(sost[str(riga.get("en"))]))
			if j >= 0:
				riga = righe[j]
	if str(pg.get(quale, "")) != "":
		pg[quale] = str(pg[quale]) + " / " + str(riga.get("nome", ""))
	else:
		pg[quale] = str(riga.get("nome", ""))
	var eff: Dictionary = riga.get("effetti", {}).duplicate(true)
	if not applica_risorse:
		eff = {"stat": eff.get("stat", {}), "xp": eff.get("xp", 0)}
	applica(eff, pg, "%s: %s" % [quale.capitalize(), riga.get("nome", "")])

## Completa la creazione: capo, equipaggiamento iniziale, nave, crediti, punti storia. equipaggio = array di personaggi.
func completa_creazione(equipaggio: Array, indice_capo := 0, nave_indice := -1) -> void:
	s["equipaggio"] = equipaggio
	for i in equipaggio.size():
		equipaggio[i]["leader"] = (i == indice_capo)
	var capo: Dictionary = equipaggio[indice_capo]
	if not Personaggio.e_robot(capo):
		capo["fortuna"] = min(int(capo.get("fortuna", 0)) + 1, max(1, Personaggio.massimo(capo, "fortuna")))
	scrivi("%s è il Capo dell'equipaggio." % capo.nome)
	# equipaggiamento iniziale
	var ini: Dictionary = Dati.f("creazione").get("equipaggiamento_iniziale", {})
	var tiri: Array = ini.get("tiri", []).duplicate()
	var sostituibili := 0
	for p in equipaggio:
		if p.get("aumento_acume", false):
			sostituibili += 1
	for i in tiri.size():
		if tiri[i] == "arma_militare" and sostituibili > 0 and dadi.d6() >= 4:
			tiri[i] = "arma_alta"
			sostituibili -= 1
	for t in tiri:
		_aggiungi_al_deposito(tira_oggetto(t), "equipaggiamento iniziale")
	s["crediti"] = int(s.get("crediti", 0)) + equipaggio.size() * int(ini.get("crediti_per_membro", 1))
	# nave
	var navi: Dictionary = Dati.f("nave").get("navi", {})
	var riga: Dictionary
	if nave_indice >= 0 and nave_indice < navi.get("righe", []).size():
		riga = navi["righe"][nave_indice]
	else:
		riga = dadi.su_tabella(navi)["riga"]
	var debito := dadi.tira(riga.get("debito", "1d6+20"))
	s["nave"] = {"nome": "Senza nome", "tipo": riga.get("nome", ""), "scafo": int(riga.get("scafo", 30)),
		"scafo_max": int(riga.get("scafo", 30)), "debito": debito, "tratti": riga.get("tratti", []), "componenti": []}
	scrivi("Nave: %s (Scafo %d, debito %d crediti)." % [riga.get("nome"), int(riga.get("scafo", 30)), debito])
	# punti storia iniziali
	var ps := 0
	if s["difficolta"] != "follia":
		ps = dadi.tira("1d6+1")
		if s["difficolta"] == "hardcore":
			ps -= 1
	s["punti_storia"] = int(s.get("punti_storia", 0)) + ps
	# distribuisce le armi: ognuno riceve un'arma da tiro se possibile
	distribuisci_automatico()
	s["fase"] = "inizio_turno"
	s["mondo"] = genera_mondo(true)
	scrivi("Inizio della campagna: %d crediti, %d punti Storia." % [s.crediti, s.punti_storia], "titolo")

## ===================== oggetti =====================

## Tira su una tabella di oggetti e restituisce l'id ("arma_militare", "equip", "gadget", "bottino"...).
func tira_oggetto(tabella: String) -> Dictionary:
	match tabella:
		"arma_militare", "arma_bassa", "arma_alta":
			var r := dadi.su_tabella(Dati.f("armi").get("tabelle", {}).get(tabella, {}))
			return {"id": str(r["riga"].get("arma", "pistola"))}
		"equip", "gadget":
			var r := dadi.su_tabella(Dati.f("equipaggiamento").get("tabelle", {}).get(tabella, {}))
			return {"id": str(r["riga"].get("oggetto", "comunicatore"))}
		"bottino":
			return tira_bottino("bottino")
		_:
			if tabella.begins_with("bottino."):
				return tira_bottino(tabella.substr(8))
			if Dati.e_arma(tabella) or not Dati.oggetto(tabella).is_empty():
				return {"id": tabella}
			return {"id": tabella, "speciale": true}

## Tabella del Bottino con sottotabelle. Restituisce un oggetto {"id", "danneggiato"?} o {"crediti": n} ecc.
func tira_bottino(tab_id: String, danneggiato := false, profondita := 0) -> Dictionary:
	var tb: Dictionary = Dati.f("bottino")
	var tab: Dictionary = tb.get(tab_id, {})
	if tab.is_empty() or profondita > 5:
		return {"id": "rottami", "speciale": true}
	var riga: Dictionary = dadi.su_tabella(tab)["riga"]
	var dann := danneggiato or bool(riga.get("danneggiato", false))
	if riga.has("tabella"):
		var n := int(riga.get("tiri", 1))
		if n > 1:
			# il secondo oggetto va direttamente nel deposito
			for i in n - 1:
				var extra := tira_bottino(str(riga["tabella"]), dann, profondita + 1)
				_aggiungi_al_deposito(extra, "bottino")
		return tira_bottino(str(riga["tabella"]), dann, profondita + 1)
	if riga.has("arma"):
		return {"id": str(riga["arma"]), "danneggiato": dann}
	if riga.has("oggetto"):
		var o := {"id": str(riga["oggetto"]), "danneggiato": dann}
		if riga.has("quantita"):
			o["usi"] = int(riga["quantita"])
		return o
	if riga.has("effetti"):
		applica(riga["effetti"], {}, "Bottino: " + str(riga.get("nome", "")))
		return {"nessuno": true, "nome": str(riga.get("nome", ""))}
	return {"id": str(riga.get("id", riga.get("nome", "oggetto"))).to_snake_case(), "nome": str(riga.get("nome", "")), "speciale": true, "testo": str(riga.get("testo", ""))}

func _aggiungi_al_deposito(o: Dictionary, fonte := "") -> void:
	if o.is_empty() or o.get("nessuno", false) or not o.has("id"):
		return
	s["deposito"].append(o)
	var nome := Dati.nome_oggetto(str(o["id"])) if not o.has("nome") else str(o["nome"])
	scrivi("Nuovo oggetto: %s%s%s." % [nome, " (danneggiato)" if o.get("danneggiato", false) else "", (" - " + fonte) if fonte != "" else ""])

## Assegnazione automatica: ogni personaggio senza arma da tiro riceve la migliore disponibile, poi le corazze.
func distribuisci_automatico() -> void:
	var dep: Array = s["deposito"]
	for pg in s["equipaggio"]:
		if Personaggio.arma_tiro(pg) == "":
			var best := -1
			var bp := -999.0
			for i in dep.size():
				var a := Dati.arma(str(dep[i].get("id")))
				if a.is_empty() or int(a.get("gittata", 0)) <= 0 or dep[i].get("danneggiato", false):
					continue
				var p := float(a.get("colpi", 1)) * (2 + int(a.get("danno", 0))) + float(a.get("gittata", 0)) / 12.0
				if p > bp:
					bp = p
					best = i
			if best >= 0:
				pg["oggetti"].append(dep[best])
				dep.remove_at(best)
	for pg in s["equipaggio"]:
		if Personaggio.arma_mischia(pg) == "":
			for i in dep.size():
				var a := Dati.arma(str(dep[i].get("id")))
				if not a.is_empty() and "mischia" in a.get("tratti", []) and not dep[i].get("danneggiato", false):
					pg["oggetti"].append(dep[i])
					dep.remove_at(i)
					break
	for pg in s["equipaggio"]:
		if Personaggio.salvezze(pg)["tutte"] == 0 or Personaggio.e_robot(pg):
			for i in dep.size():
				var o := Dati.oggetto(str(dep[i].get("id")))
				if str(o.get("tipo", "")) in ["corazza", "schermo"] and not dep[i].get("danneggiato", false):
					pg["oggetti"].append(dep[i])
					dep.remove_at(i)
					break

func sposta_oggetto(da_pg: String, indice: int, a_pg: String) -> void:
	var sorgente: Array = s["deposito"] if da_pg == "" else trova(da_pg).get("oggetti", [])
	if indice < 0 or indice >= sorgente.size():
		return
	var o = sorgente[indice]
	sorgente.remove_at(indice)
	if a_pg == "":
		s["deposito"].append(o)
	else:
		trova(a_pg)["oggetti"].append(o)

func trova(id: String) -> Dictionary:
	for p in s.get("equipaggio", []):
		if p.get("id") == id:
			return p
	return {}

func vivi() -> Array:
	var r := []
	for p in s.get("equipaggio", []):
		if not p.get("morto", false):
			r.append(p)
	return r

func disponibili() -> Array:
	var r := []
	for p in vivi():
		if Personaggio.disponibile(p):
			r.append(p)
	return r

func membro_casuale(escludi_robot := false) -> Dictionary:
	var c := []
	for p in vivi():
		if not p.get("assente", false) and not (escludi_robot and Personaggio.e_robot(p)):
			c.append(p)
	return dadi.scegli(c) if not c.is_empty() else {}

func ha_specie(id: String) -> bool:
	id = id_specie(id)
	for p in vivi():
		if p.get("specie") == id:
			return true
	return false

## ===================== effetti =====================

## Applica un dizionario di effetti (vedi data/LEGGIMI_DATI.md). pg = personaggio interessato (può essere vuoto).
## Gli effetti non automatizzati vengono annotati nel diario come promemoria.
func applica(eff: Dictionary, pg: Dictionary = {}, fonte := "") -> void:
	if eff.is_empty():
		return
	if eff.has("se_specie") and not pg.is_empty():
		var ss: Dictionary = eff["se_specie"]
		var sp := str(pg.get("specie"))
		for k in ss:
			if id_specie(k) == sp:
				applica(ss[k], pg, fonte)
	if eff.has("specie_immuni") and not pg.is_empty():
		for k in eff["specie_immuni"]:
			if id_specie(str(k)) == str(pg.get("specie")):
				scrivi("%s non è interessato (%s)." % [pg.nome, Personaggio.nome_specie(pg)])
				return
	for k in eff:
		var v = eff[k]
		match k:
			"stat":
				if not pg.is_empty():
					for st in v:
						Personaggio.modifica_stat(pg, st, int(v[st]))
						scrivi("%s: %s %+d." % [pg.nome, Personaggio.nome_stat(st), int(v[st])])
			"crediti":
				var n := dadi.tira(v)
				if eff.get("mod_ingegnere", 0) and ha_specie("engineer") and n < 0:
					n += 1
				s["crediti"] = max(0, int(s.crediti) + n)
				scrivi("%s %d crediti%s." % ["Guadagnati" if n >= 0 else "Spesi", abs(n), _fonte(fonte)])
			"punti_storia":
				if s.get("difficolta") == "follia":
					continue
				var n := dadi.tira(v)
				s["punti_storia"] = max(0, int(s.punti_storia) + n)
				scrivi("Punti Storia %+d%s." % [n, _fonte(fonte)])
			"dicerie":
				var n := dadi.tira(v)
				if not s.get("missione", {}).is_empty():
					s["dicerie_missione"] = int(s.get("dicerie_missione", 0)) + n
					scrivi("Dicerie di Missione %+d%s." % [n, _fonte(fonte)])
				else:
					s["dicerie"] = max(0, int(s.dicerie) + n)
					scrivi("Dicerie %+d%s." % [n, _fonte(fonte)])
			"patrono":
				for i in int(v):
					aggiungi_patrono(fonte)
			"rivale":
				if int(v) > 0:
					for i in int(v):
						aggiungi_rivale(fonte)
				elif int(v) < 0 and not s.rivali.is_empty():
					var r = s.rivali.pop_back()
					scrivi("Rivale rimosso: %s." % r.get("nome", "?"))
			"xp":
				var n := dadi.tira(v)
				if not pg.is_empty():
					Personaggio.modifica_stat(pg, "xp", n)
					scrivi("%s guadagna %d XP%s." % [pg.nome, n, _fonte(fonte)])
			"xp_casuale", "xp_casuali":
				var b := membro_casuale(true)
				if not b.is_empty():
					var n := dadi.tira(v)
					Personaggio.modifica_stat(b, "xp", n)
					scrivi("%s guadagna %d XP%s." % [b.nome, n, _fonte(fonte)])
			"xp_tutti", "xp_tutto_equipaggio":
				for p in vivi():
					Personaggio.modifica_stat(p, "xp", dadi.tira(v))
				scrivi("Tutto l'equipaggio guadagna XP%s." % _fonte(fonte))
			"oggetti":
				for t in v:
					var o := tira_oggetto(str(t))
					if eff.get("monouso", false):
						o["usi"] = 1
					_aggiungi_al_deposito(o, fonte)
			"tiro_tabella", "tabella":
				_tiro_su_tabella(str(v), pg, fonte)
			"scafo":
				var n := dadi.tira(v)
				var nave: Dictionary = s.get("nave", {})
				if nave.is_empty():
					continue
				if n < 0 and "corazzata" in nave.get("tratti", []):
					n = min(0, n + 1)
				nave["scafo"] = clampi(int(nave.scafo) + n, 0, int(nave.scafo_max))
				scrivi("Scafo della nave %+d (ora %d/%d)%s." % [n, nave.scafo, nave.scafo_max, _fonte(fonte)])
			"debito":
				var n := dadi.tira(v)
				s["nave"]["debito"] = max(0, int(s.nave.get("debito", 0)) + n)
				scrivi("Debito della nave %+d%s." % [n, _fonte(fonte)])
			"ferito_casuale", "infermeria", "turni_recupero":
				var b: Dictionary = pg if (k != "ferito_casuale" and not pg.is_empty()) else membro_casuale()
				if not b.is_empty():
					var n := dadi.tira(v)
					if n > 0:
						b["infermeria"] = int(b.get("infermeria", 0)) + n
						scrivi("%s passa %d turni in Infermeria%s." % [b.nome, n, _fonte(fonte)])
			"recupero", "recupero_tutti":
				var n := dadi.tira(v)
				var quanti := int(eff.get("bersagli", 99))
				for p in vivi():
					if quanti <= 0:
						break
					if int(p.get("infermeria", 0)) > 0:
						p["infermeria"] = max(0, int(p.infermeria) - n)
						quanti -= 1
						scrivi("%s recupera %d turni di Infermeria." % [p.nome, n])
			"perde_oggetto":
				var b: Dictionary = pg if not pg.is_empty() else membro_casuale()
				if not b.is_empty() and not b.get("oggetti", []).is_empty():
					var i := dadi.d(b.oggetti.size()) - 1
					scrivi("%s perde %s." % [b.nome, Dati.nome_oggetto(str(b.oggetti[i].id))])
					b.oggetti.remove_at(i)
			"danneggia_equip", "danneggia_oggetto", "oggetti_danneggiati":
				var b: Dictionary = pg if not pg.is_empty() else membro_casuale()
				if b.is_empty() or b.get("oggetti", []).is_empty():
					continue
				if str(v) == "tutto":
					for o in b.oggetti:
						o["danneggiato"] = true
					scrivi("Tutto l'equipaggiamento di %s è danneggiato." % b.nome)
				else:
					var o = dadi.scegli(b.oggetti)
					o["danneggiato"] = true
					scrivi("%s: %s danneggiato." % [b.nome, Dati.nome_oggetto(str(o.id))])
			"morte":
				if not pg.is_empty() and v:
					uccidi(pg, fonte)
			"perde_tutto":
				if not pg.is_empty():
					pg["oggetti"] = []
					scrivi("%s perde tutto l'equipaggiamento che portava." % pg.nome)
			"prova":
				_prova(v, pg, fonte)
			"scelte":
				s["scelte"].append({"testo": fonte, "opzioni": v, "pg": pg.get("id", "")})
			"nuovo_membro", "recluta", "recluta_compagno":
				if v:
					recluta(fonte)
			"offerta_patrono", "trova_patrono":
				for i in int(v if (v is int or v is float) else 1):
					s["offerte"].append(genera_lavoro(true))
				scrivi("Un Patrono offre un lavoro%s." % _fonte(fonte))
			"ripara_oggetto", "ripara":
				for p in vivi():
					for o in p.get("oggetti", []):
						if o.get("danneggiato", false):
							o["danneggiato"] = false
							scrivi("%s riparato." % Dati.nome_oggetto(str(o.id)))
							return
			"invasione":
				s["mondo"]["mod_invasione"] = int(s.mondo.get("mod_invasione", 0)) + int(v)
			"salta_battaglia_turni", "niente_compiti_turni", "assente_turni":
				if not pg.is_empty():
					pg[k] = int(v)
					if k == "assente_turni":
						pg["assente"] = true
			"flag":
				s["flag"][str(v)] = true
			"manuale":
				pass
			_:
				pass
	if eff.get("manuale", false):
		scrivi("Da applicare a mano%s." % _fonte(fonte), "manuale")

static func testo_valore(v) -> String:
	if v is float and v == floor(v):
		return "%d crediti" % int(v)
	if v is int:
		return "%d crediti" % v
	return str(v).replace("d", "D") + " crediti"

func _fonte(f: String) -> String:
	return "" if f == "" else " (" + f + ")"

func _tiro_su_tabella(nome: String, pg: Dictionary, fonte: String) -> void:
	if nome.begins_with("bottino"):
		_aggiungi_al_deposito(tira_bottino(nome.substr(8) if nome.begins_with("bottino.") else "bottino"), fonte)
		return
	var tab: Dictionary = Dati.f("campagna").get(nome, {})
	if tab.is_empty():
		scrivi("Tira sulla tabella «%s»%s." % [nome, _fonte(fonte)], "manuale")
		return
	var r := dadi.su_tabella(tab)
	scrivi("%s (%d): %s" % [nome.capitalize(), r.tiro, r.riga.get("testo", r.riga.get("nome", ""))])
	applica(r.riga.get("effetti", {}), pg, str(r.riga.get("nome", "")))

## Prova: 1D6 (+ statistica del membro migliore o del personaggio) contro una soglia.
func _prova(p: Dictionary, pg: Dictionary, fonte: String) -> void:
	var rip := int(p.get("ripetizioni", 1))
	for i in rip:
		var stat = p.get("stat")
		var chi: Dictionary = pg
		if stat != null and chi.is_empty():
			var best := -99
			for m in disponibili():
				if int(m.get(stat, 0)) > best:
					best = int(m.get(stat, 0))
					chi = m
		var t := dadi.tira(p.get("dado", "1d6"))
		var bon := int(chi.get(stat, 0)) if stat != null and not chi.is_empty() else 0
		var ok := t + bon >= int(p.get("soglia", 4))
		scrivi("Prova%s: %d%s contro %d+: %s." % [_fonte(fonte), t, (" %+d (%s, %s)" % [bon, Personaggio.nome_stat(str(stat)), chi.get("nome", "")]) if stat != null else "", int(p.get("soglia", 4)), "riuscita" if ok else "fallita"])
		applica(p.get("successo" if ok else "fallimento", {}), chi, fonte)

## Risolve la prima scelta in sospeso (indice dell'opzione).
func risolvi_scelta(opzione: int) -> void:
	if s["scelte"].is_empty():
		return
	var sc: Dictionary = s["scelte"].pop_front()
	var ops: Array = sc.get("opzioni", [])
	if ops.is_empty():
		return
	opzione = clampi(opzione, 0, ops.size() - 1)
	var o: Dictionary = ops[opzione]
	scrivi("Scelta: %s." % o.get("testo", ""))
	applica(o.get("effetti", {}), trova(str(sc.get("pg", ""))), str(sc.get("testo", "")))

func ha_scelte() -> bool:
	return not s.get("scelte", []).is_empty()

## ===================== rivali, patroni, reclute =====================

func aggiungi_rivale(fonte := "", tipo_nemico := "") -> void:
	if tipo_nemico == "":
		var cat := dadi.su_tabella(Dati.f("incontri").get("categorie", {}).get("tabella", {}))
		tipo_nemico = _nemico_casuale(_categoria_da_colonna("rivale"))
	var n := Dati.nemico(tipo_nemico)
	var r := {"id": "riv%d" % dadi.d(999999), "nome": str(n.get("nome", "Rivale")), "nemico": tipo_nemico,
		"categoria": str(n.get("categoria", "")), "rintracciato": false, "mondo": s.get("mondo", {}).get("nome", "")}
	s["rivali"].append(r)
	scrivi("Nuovo Rivale: %s%s." % [r.nome, _fonte(fonte)], "rivale")

func aggiungi_patrono(fonte := "") -> void:
	var t := dadi.su_tabella(Dati.f("campagna").get("patroni", {}).get("tipo", {}))
	var p := {"id": "pat%d" % dadi.d(999999), "nome": str(t.riga.get("nome", "Patrono")), "tipo": str(t.riga.get("id", "")),
		"persistente": false}
	s["patroni"].append(p)
	scrivi("Nuovo Patrono: %s%s." % [p.nome, _fonte(fonte)], "patrono")

func recluta(fonte := "") -> void:
	var pg := Personaggio.da_specie(tira_specie(), nome_casuale())
	pg["oggetti"] = [{"id": "pistola"}]
	s["equipaggio"].append(pg)
	s["crediti"] = int(s.crediti) + 1
	scrivi("Si unisce all'equipaggio %s%s." % [Personaggio.descrizione_breve(pg), _fonte(fonte)], "recluta")

func uccidi(pg: Dictionary, fonte := "") -> void:
	if pg.get("morto", false):
		return
	pg["morto"] = true
	s["statistiche"]["morti"] = int(s.statistiche.get("morti", 0)) + 1
	scrivi("%s è morto%s." % [pg.nome, _fonte(fonte)], "morte")
	if pg.get("leader", false):
		var v := vivi()
		if not v.is_empty():
			v[0]["leader"] = true
			scrivi("%s diventa il nuovo Capo." % v[0].nome)

## ===================== mondo =====================

const NOMI_MONDI := ["Rashor IV", "Kessel Morto", "Nuova Speranza", "Tarsis", "Vega Bassa", "Draxis", "Halcyon", "Morrow",
	"Porto Ferro", "Sabbie di Ul", "Cinder", "Aurelia", "Gorgon", "Nimbus", "Varka", "Ostrava", "Lumen", "Pellucida",
	"Thule", "Brisa", "Kharon", "Elysia", "Ruggine", "Zephyr", "Mirage", "Orlo di Sigma", "Kobalt", "Ishtar", "Fenice", "Vortice"]

func genera_mondo(inizio := false) -> Dictionary:
	var m := {"nome": dadi.scegli(NOMI_MONDI) + ("" if dadi.d6() < 4 else " " + ["II", "III", "Prime", "B", "Minore"][dadi.d(5) - 1]),
		"tratti": [], "licenza_richiesta": false, "licenza": false, "invaso": false, "turni": 0}
	var tab: Dictionary = Dati.f("campagna").get("tratti_mondo", {})
	if not tab.is_empty():
		var r := dadi.su_tabella(tab)
		m["tratti"].append({"nome": r.riga.get("nome", ""), "testo": r.riga.get("testo", ""), "effetti": r.riga.get("effetti", {})})
	# licenza
	var arr: Dictionary = Dati.f("campagna").get("arrivo", {})
	if dadi.d6() >= 5:
		m["licenza_richiesta"] = true
		m["costo_licenza"] = dadi.d6()
	if not inizio:
		s["mondi_visitati"] = int(s.get("mondi_visitati", 0)) + 1
	return m

func tratto_mondo(chiave: String):
	for t in s.get("mondo", {}).get("tratti", []):
		if t.get("effetti", {}).has(chiave):
			return t.effetti[chiave]
	return null

## ===================== turno di campagna =====================

func inizia_turno() -> void:
	s["turno"] = int(s.turno) + 1
	s["statistiche"]["turni"] = int(s.turno)
	s["fase"] = "viaggio"
	s["incarichi"] = {}
	s["battaglia"] = {}
	s["esito"] = {}
	s["mondo"]["turni"] = int(s.mondo.get("turni", 0)) + 1
	scrivi("TURNO %d - %s" % [s.turno, s.mondo.get("nome", "")], "titolo")
	if int(s.turno) % 3 == 0 and s.difficolta != "follia":
		s["punti_storia"] = int(s.punti_storia) + 1
		scrivi("La reputazione cresce: +1 punto Storia.")
	# recupero in infermeria e assenze
	for p in vivi():
		if int(p.get("infermeria", 0)) > 0:
			p["infermeria"] = int(p.infermeria) - 1
			p["appena_dimesso"] = int(p.infermeria) == 0
			if int(p.infermeria) == 0:
				scrivi("%s esce dall'Infermeria." % p.nome)
		else:
			p["appena_dimesso"] = false
		for k in ["salta_battaglia_turni", "niente_compiti_turni"]:
			if int(p.get(k, 0)) > 0:
				p[k] = int(p[k]) - 1
		if p.get("assente", false):
			p["assente_turni"] = int(p.get("assente_turni", 1)) - 1
			if int(p.assente_turni) <= 0:
				p["assente"] = false
				scrivi("%s torna dall'equipaggio." % p.nome)
	# scadenza dei lavori dei patroni
	var lav: Dictionary = s.get("lavoro", {})
	if not lav.is_empty() and lav.get("turni") != null:
		lav["turni"] = int(lav.turni) - 1
		if int(lav.turni) < 0:
			scrivi("Il lavoro per %s è scaduto: conta come fallito." % lav.get("patrono", "il Patrono"))
			s["lavoro"] = {}

## Passo di viaggio. viaggia = true per partire verso un nuovo mondo.
func passo_viaggio(viaggia: bool) -> void:
	var m: Dictionary = s.mondo
	if m.get("invasione_imminente", false):
		var t := dadi.tira("2d6")
		if t >= 8:
			scrivi("Fuga dall'Invasione: %d, riuscita!" % t)
			viaggia = true
		else:
			scrivi("Fuga dall'Invasione: %d, fallita. Dovete combattere una battaglia d'Invasione." % t, "pericolo")
			s["flag"]["battaglia_invasione"] = true
			s["fase"] = "equipaggiamento"
			return
	if viaggia:
		var costo := int(Dati.f("nave").get("parametri", {}).get("costo_viaggio", 5))
		if s.nave.is_empty():
			costo = vivi().size()
		if int(s.crediti) < costo:
			scrivi("Non avete abbastanza crediti per il carburante (%d): restate qui." % costo, "pericolo")
		else:
			s["crediti"] = int(s.crediti) - costo
			scrivi("Partenza: %d crediti di carburante." % costo)
			var ev := dadi.su_tabella(Dati.f("nave").get("eventi_viaggio", Dati.f("campagna").get("eventi_viaggio", {})))
			scrivi("Evento di viaggio (%d): %s - %s" % [ev.tiro, ev.riga.get("nome", ""), ev.riga.get("testo", "")], "evento")
			applica(ev.riga.get("effetti", {}), {}, str(ev.riga.get("nome", "")))
			_arrivo()
	s["fase"] = "mantenimento"

func _arrivo() -> void:
	# rivali che seguono
	var restano := []
	for r in s.rivali:
		if dadi.d6() >= 5:
			restano.append(r)
			scrivi("Il Rivale %s vi segue." % r.nome)
		else:
			scrivi("Il Rivale %s resta indietro." % r.nome)
	s["rivali"] = restano
	var pers := []
	for p in s.patroni:
		if p.get("persistente", false):
			pers.append(p)
	s["patroni"] = pers
	s["offerte"] = []
	if not s.lavoro.is_empty() and not s.lavoro.get("persistente", false):
		s["lavoro"] = {}
	s["mondo"] = genera_mondo()
	var t := ""
	for tr in s.mondo.tratti:
		t += " " + str(tr.nome) + ": " + str(tr.testo)
	scrivi("Arrivo su %s.%s" % [s.mondo.nome, t], "titolo")
	if s.mondo.licenza_richiesta:
		scrivi("Su questo mondo serve una Licenza da libero professionista (%d crediti) per i lavori dei Patroni." % s.mondo.costo_licenza)

func compra_licenza() -> bool:
	if not s.mondo.get("licenza_richiesta", false) or s.mondo.get("licenza", false):
		return true
	var c := int(s.mondo.get("costo_licenza", 3))
	if int(s.crediti) < c:
		return false
	s["crediti"] = int(s.crediti) - c
	s["mondo"]["licenza"] = true
	scrivi("Licenza acquistata per %d crediti." % c)
	return true

## Costo del mantenimento (p.76).
func costo_mantenimento() -> int:
	var n := 0
	for p in vivi():
		if int(p.get("infermeria", 0)) <= 0 and not p.get("assente", false):
			n += 1
	return 1 + max(0, n - 6)

## Mantenimento, riparazioni e debito. pagamento_debito = crediti versati sul debito; riparazioni = crediti per lo scafo.
func passo_mantenimento(pagamento_debito := 0, riparazioni := 0) -> void:
	var c := costo_mantenimento()
	var pagati: int = min(c, int(s.crediti))
	s["crediti"] = int(s.crediti) - pagati
	s["rifiutano"] = c - pagati
	scrivi("Mantenimento: %d crediti%s." % [c, "" if pagati == c else (" (mancano %d: %d membri rifiutano gli incarichi)" % [c - pagati, c - pagati])])
	var nave: Dictionary = s.nave
	if not nave.is_empty():
		if int(nave.scafo) < int(nave.scafo_max):
			nave["scafo"] = min(int(nave.scafo_max), int(nave.scafo) + 1)
			var r: int = min(riparazioni, int(s.crediti), int(nave.scafo_max) - int(nave.scafo))
			nave["scafo"] = int(nave.scafo) + r
			s["crediti"] = int(s.crediti) - r
			scrivi("Riparazioni: scafo %d/%d." % [nave.scafo, nave.scafo_max])
		var pd: int = min(pagamento_debito, int(s.crediti), int(nave.get("debito", 0)))
		if pd > 0:
			nave["debito"] = int(nave.debito) - pd
			s["crediti"] = int(s.crediti) - pd
			scrivi("Pagati %d crediti di debito." % pd)
		if int(nave.get("debito", 0)) > 0:
			nave["debito"] = int(nave.debito) + (2 if int(nave.debito) >= 31 else 1)
			scrivi("Interessi: il debito sale a %d crediti." % nave.debito)
			if int(nave.debito) >= 75:
				var t := dadi.tira("2d6")
				if t == 2 or t >= 6:
					scrivi("I creditori sequestrano la nave! (tiro %d)" % t, "pericolo")
					s["nave"] = {}
				else:
					scrivi("I creditori minacciano di sequestrare la nave (tiro %d)." % t, "pericolo")
	s["fase"] = "incarichi"

const INCARICHI := ["trova_patrono", "addestrarsi", "commerciare", "reclutare", "esplorare", "rintracciare", "riparare", "esca", "riposo"]
const NOMI_INCARICHI := {"trova_patrono": "Trovare un Patrono", "addestrarsi": "Addestrarsi", "commerciare": "Commerciare",
	"reclutare": "Reclutare", "esplorare": "Esplorare", "rintracciare": "Rintracciare un Rivale", "riparare": "Riparare",
	"esca": "Fare da esca", "riposo": "Nessun incarico"}

func puo_lavorare(p: Dictionary) -> bool:
	return Personaggio.disponibile(p) and not p.get("appena_dimesso", false) and int(p.get("niente_compiti_turni", 0)) <= 0

## Risolve gli incarichi. assegnati = {id_personaggio: incarico}; opz = {"crediti_patrono": n, "crediti_rintraccia": n,
## "tiri_commercio_extra": n, "crediti_riparare": n}
func passo_incarichi(assegnati: Dictionary, opz := {}) -> void:
	var per := {}
	var rifiutano := int(s.get("rifiutano", 0))
	for p in vivi():
		var t := str(assegnati.get(p.id, "riposo"))
		if not puo_lavorare(p) or t == "riposo":
			continue
		if rifiutano > 0:
			rifiutano -= 1
			scrivi("%s rifiuta di lavorare (mantenimento non pagato)." % p.nome)
			continue
		if not per.has(t):
			per[t] = []
		if per[t].size() >= 2 and t != "addestrarsi" and t != "commerciare" and t != "esplorare":
			scrivi("%s: al massimo 2 membri per incarico." % p.nome)
			continue
		per[t].append(p)
	s["incarichi"] = {}
	for t in per:
		for p in per[t]:
			s["incarichi"][p.id] = t
	# Trovare un Patrono
	if per.has("trova_patrono"):
		var mod: int = per.trova_patrono.size() + s.patroni.size() + int(opz.get("crediti_patrono", 0))
		for p in per.trova_patrono:
			if p.get("specie") == "manipolatore":
				mod += 1
		s["crediti"] = max(0, int(s.crediti) - int(opz.get("crediti_patrono", 0)))
		var t := dadi.d6()
		var tot := t + mod
		var n := 0 if tot < 5 else (1 if tot < 6 else 2)
		scrivi("Ricerca di Patroni: %d%+d = %d: %s." % [t, mod, tot, ["nessuna offerta", "un'offerta", "due offerte"][n]])
		for i in n:
			s["offerte"].append(genera_lavoro(i == 0 and not s.patroni.is_empty()))
	if per.has("addestrarsi"):
		for p in per.addestrarsi:
			Personaggio.modifica_stat(p, "xp", 1)
			scrivi("%s si addestra: +1 XP." % p.nome)
	if per.has("commerciare"):
		var n: int = per.commerciare.size()
		var extra: int = min(int(opz.get("tiri_commercio_extra", 0)), int(s.crediti) / 3)
		s["crediti"] = int(s.crediti) - extra * 3
		for i in n + extra:
			var chi: Dictionary = per.commerciare[min(i, n - 1)]
			var r := dadi.su_tabella(Dati.f("campagna").get("commercio", {}))
			scrivi("Commercio (%s, %d): %s - %s" % [chi.nome, r.tiro, r.riga.get("nome", ""), r.riga.get("testo", "")], "evento")
			applica(r.riga.get("effetti", {}), chi, str(r.riga.get("nome", "")))
	if per.has("esplorare"):
		for p in per.esplorare:
			var r := dadi.su_tabella(Dati.f("campagna").get("esplorazione", {}))
			scrivi("Esplorazione (%s, %d): %s - %s" % [p.nome, r.tiro, r.riga.get("nome", ""), r.riga.get("testo", "")], "evento")
			applica(r.riga.get("effetti", {}), p, str(r.riga.get("nome", "")))
	if per.has("reclutare"):
		var n: int = per.reclutare.size()
		var attivi := vivi().size()
		if attivi < 6:
			for i in min(n, 6 - attivi):
				recluta("Reclutare")
		else:
			var t := dadi.d6() + n
			scrivi("Reclutamento: %d (serve 6+)." % t)
			if t >= 6:
				recluta("Reclutare")
	if per.has("rintracciare") and not s.rivali.is_empty():
		var cr := int(opz.get("crediti_rintraccia", 0))
		cr = min(cr, int(s.crediti))
		s["crediti"] = int(s.crediti) - cr
		var t := dadi.d6()
		var tot: int = t + per.rintracciare.size() + cr
		if tot >= 6:
			var r = s.rivali[0]
			r["rintracciato"] = true
			scrivi("Rintracciare: %d, avete localizzato il Rivale %s: potete attaccarlo in questo turno." % [tot, r.nome])
		else:
			scrivi("Rintracciare: %d, nessuna traccia (serve 6+)." % tot)
	if per.has("riparare"):
		for p in per.riparare:
			var bersaglio := {}
			for q in vivi():
				for o in q.get("oggetti", []):
					if o.get("danneggiato", false) and bersaglio.is_empty():
						bersaglio = o
			for o in s.deposito:
				if o.get("danneggiato", false) and bersaglio.is_empty():
					bersaglio = o
			if bersaglio.is_empty():
				scrivi("%s non trova nulla da riparare." % p.nome)
				continue
			var cr: int = min(int(opz.get("crediti_riparare", 0)), int(s.crediti))
			s["crediti"] = int(s.crediti) - cr
			var t := dadi.d6()
			var tot := t + int(p.acume) + (1 if p.specie == "engineer" else 0) + cr
			if t == 1:
				scrivi("%s rovina definitivamente %s (1 naturale)." % [p.nome, Dati.nome_oggetto(str(bersaglio.id))])
				bersaglio["distrutto"] = true
				_rimuovi_distrutti()
			elif tot >= 6:
				bersaglio["danneggiato"] = false
				scrivi("%s ripara %s (%d)." % [p.nome, Dati.nome_oggetto(str(bersaglio.id)), tot])
			else:
				scrivi("%s non riesce a riparare %s (%d, serve 6+)." % [p.nome, Dati.nome_oggetto(str(bersaglio.id)), tot])
	s["esche"] = per.get("esca", []).size()
	s["fase"] = "lavori"

func _rimuovi_distrutti() -> void:
	for p in vivi():
		p["oggetti"] = p.oggetti.filter(func(o): return not o.get("distrutto", false))
	s["deposito"] = s.deposito.filter(func(o): return not o.get("distrutto", false))

## Genera un'offerta di lavoro di un Patrono (p.83-84).
func genera_lavoro(esistente := false) -> Dictionary:
	var pt: Dictionary = Dati.f("campagna").get("patroni", {})
	var patrono := {}
	if esistente and not s.patroni.is_empty():
		patrono = dadi.scegli(s.patroni)
	else:
		var t := dadi.su_tabella(pt.get("tipo", {}))
		patrono = {"id": "pat%d" % dadi.d(999999), "nome": str(t.riga.get("nome", "Patrono")), "tipo": str(t.riga.get("id", "")), "persistente": false}
		s["patroni"].append(patrono)
	var tipo := str(patrono.get("tipo", ""))
	var pp := dadi.su_tabella(pt.get("paga_pericolo", {}), 1 if tipo == "corporazione" else 0)
	var tf := dadi.su_tabella(pt.get("tempistica", {}), 1 if tipo == "gruppo_segreto" else 0)
	var soglie: Dictionary = pt.get("bhc_soglie", {}).get(tipo, {"benefici": 8, "rischi": 8, "condizioni": 8})
	var lav := {"patrono": patrono.nome, "id_patrono": patrono.id, "tipo": tipo,
		"paga_pericolo": pp.riga.get("effetti", {}).get("crediti", 1), "paga_testo": str(pp.riga.get("testo", "")),
		"turni": tf.riga.get("turni"), "tempistica": str(tf.riga.get("testo", "")), "extra": []}
	for cat in ["benefici", "rischi", "condizioni"]:
		if dadi.d10() >= int(soglie.get(cat, 8)):
			var r := dadi.su_tabella(pt.get(cat, {}))
			lav["extra"].append({"categoria": cat, "nome": r.riga.get("nome", ""), "testo": r.riga.get("testo", ""), "effetti": r.riga.get("effetti", {})})
			if r.riga.get("id", "") == "persistente":
				lav["persistente"] = true
	lav["obiettivo"] = str(dadi.su_tabella(Dati.f("incontri").get("obiettivi", {}).get("patrono", {})).riga.get("obiettivo", "respingere"))
	return lav

func accetta_lavoro(i: int) -> void:
	if i >= 0 and i < s.offerte.size():
		if s.mondo.get("licenza_richiesta", false) and not s.mondo.get("licenza", false):
			if not compra_licenza():
				scrivi("Serve una Licenza per lavorare qui e non avete abbastanza crediti.", "pericolo")
				return
		s["lavoro"] = s.offerte[i]
		scrivi("Lavoro accettato per %s: obiettivo %s, paga di pericolo %s, %s." % [s.lavoro.patrono, nome_obiettivo(s.lavoro.obiettivo), Campagna.testo_valore(s.lavoro.paga_pericolo), s.lavoro.tempistica.to_lower()], "patrono")
		for e in s.lavoro.extra:
			scrivi("  %s: %s - %s" % [e.categoria.capitalize(), e.nome, e.testo])
	s["offerte"] = []
	s["fase"] = "equipaggiamento"

func passo_lavori_fine() -> void:
	s["offerte"] = []
	s["fase"] = "equipaggiamento"

func passo_equipaggiamento_fine() -> void:
	s["fase"] = "dicerie"
	if s.flag.get("battaglia_invasione", false):
		s["fase"] = "scelta_battaglia"

func passo_dicerie() -> void:
	if s.missione.is_empty() and int(s.dicerie) > 0:
		var t := dadi.d6()
		if t <= int(s.dicerie):
			s["dicerie"] = 0
			s["missione"] = {"attiva": true, "finale": false, "inizio": int(s.turno)}
			s["dicerie_missione"] = 0
			var nat := dadi.su_tabella(Dati.f("campagna").get("dicerie_missione", {}).get("natura_diceria", {}))
			scrivi("Le Dicerie portano a una Missione! (tiro %d) Indizio: %s." % [t, str(nat.riga.get("nome", "")).to_lower()], "missione")
		else:
			scrivi("Dicerie: tiro %d, nessuna Missione per ora (%d Dicerie)." % [t, s.dicerie])
	s["fase"] = "scelta_battaglia"

## Controllo dei Rivali (p.85): restituisce il rivale che attacca o {}.
func controllo_rivali() -> Dictionary:
	if s.rivali.is_empty():
		return {}
	var t := dadi.d6() + int(s.get("esche", 0))
	if t <= s.rivali.size():
		var r: Dictionary = dadi.scegli(s.rivali)
		scrivi("Controllo dei Rivali: %d. %s vi ha rintracciato!" % [t, r.nome], "pericolo")
		return r
	scrivi("Controllo dei Rivali: %d, nessun attacco." % t)
	return {}

## Opzioni di battaglia disponibili in questo turno.
func opzioni_battaglia() -> Array:
	var o := []
	if s.flag.get("battaglia_invasione", false):
		return [{"tipo": "invasione", "nome": "Battaglia d'Invasione (obbligatoria)"}]
	o.append({"tipo": "opportunita", "nome": "Missione d'Opportunità"})
	if not s.lavoro.is_empty():
		o.append({"tipo": "patrono", "nome": "Lavoro per %s (%s)" % [s.lavoro.patrono, nome_obiettivo(s.lavoro.obiettivo)]})
	if not s.missione.is_empty():
		o.append({"tipo": "missione", "nome": "Proseguire la Missione" + (" (finale)" if s.missione.get("finale", false) else "")})
	for r in s.rivali:
		if r.get("rintracciato", false):
			o.append({"tipo": "attacca_rivale", "nome": "Attaccare il Rivale " + r.nome, "rivale": r.id})
	if s.opzioni.get("zone", true) and s.zona_rossa.get("licenza", false):
		o.append({"tipo": "zona_rossa", "nome": "Lavoro in Zona Rossa"})
	o.append({"tipo": "nessuna", "nome": "Nessuna battaglia questo turno"})
	return o

func nome_obiettivo(id: String) -> String:
	return str(Dati.f("incontri").get("tipi_obiettivo", {}).get(id, {}).get("nome", id.capitalize()))

## ===================== preparazione della battaglia =====================

func _categoria_da_colonna(colonna: String) -> String:
	var cat: Dictionary = Dati.f("incontri").get("categorie", {})
	var tab: Dictionary = cat.get("tabella", cat)
	var t := dadi.d100()
	for r in tab.get("righe", []):
		if r.has(colonna):
			var iv = r[colonna]
			if iv is Array and iv.size() == 2 and t >= int(iv[0]) and t <= int(iv[1]):
				return str(r.get("categoria", r.get("id", "elementi_criminali")))
	# formato alternativo: colonne con righe proprie
	if tab.has(colonna):
		return str(Dadi.riga(tab[colonna], t).get("categoria", "elementi_criminali"))
	if cat.has("colonne") and cat.colonne.has(colonna):
		return str(Dadi.riga(cat.colonne[colonna], t).get("categoria", "elementi_criminali"))
	return dadi.scegli(["elementi_criminali", "forza_mercenaria", "parti_interessate", "minacce_vaganti"])

func _nemico_casuale(categoria: String) -> String:
	var tab: Dictionary = Dati.f("incontri").get("tabelle_nemici", {}).get(categoria, {})
	if tab.is_empty():
		return "ganger"
	return str(dadi.su_tabella(tab).riga.get("nemico", "ganger"))

## Prepara una battaglia: tipo = opportunita | patrono | missione | attacca_rivale | rivale | invasione | zona_rossa.
func prepara_battaglia(tipo: String, extra := {}) -> Dictionary:
	var inc: Dictionary = Dati.f("incontri")
	var b := {"tipo": tipo, "obiettivo": "respingere", "nemico": "", "categoria": "", "condizione": {}, "luogo": {},
		"zona_rossa": tipo == "zona_rossa", "rivale": "", "unici": [], "numero": 0}
	var colonna := "opportunita"
	match tipo:
		"patrono":
			colonna = "patrono"
			b.obiettivo = str(s.lavoro.get("obiettivo", "respingere"))
		"missione":
			colonna = "missione"
			if s.missione.get("finale", false):
				b.obiettivo = "respingere"
			else:
				b.obiettivo = str(dadi.su_tabella(inc.get("obiettivi", {}).get("missione", {})).riga.get("obiettivo", "respingere"))
		"attacca_rivale", "rivale":
			colonna = "rivale"
			var riv := {}
			for r in s.rivali:
				if r.id == str(extra.get("rivale", "")) or riv.is_empty():
					riv = r
			b.rivale = str(riv.get("id", ""))
			b.nemico = str(riv.get("nemico", ""))
			if tipo == "rivale":
				var ra: Dictionary = inc.get("obiettivi", {}).get("rivale", {})
				b.obiettivo = str(dadi.su_tabella(ra).riga.get("obiettivo", "imboscata")) if not ra.is_empty() else "imboscata"
			else:
				b.obiettivo = "respingere"
		"invasione":
			colonna = "invasione"
			b.obiettivo = "invasione"
		_:
			colonna = "opportunita"
			b.obiettivo = str(dadi.su_tabella(inc.get("obiettivi", {}).get("opportunita", {})).riga.get("obiettivo", "respingere"))
	if b.nemico == "":
		b.categoria = _categoria_da_colonna("rivale" if colonna == "invasione" else colonna)
		if tipo == "invasione":
			b.categoria = "minacce_vaganti"
		b.nemico = _nemico_casuale(b.categoria)
	var nem := Dati.nemico(b.nemico)
	b.categoria = str(nem.get("categoria", b.categoria))
	# condizioni di schieramento e luoghi notevoli
	if tipo != "invasione":
		var cs: Dictionary = inc.get("condizioni_schieramento", {})
		var col := "patrono" if colonna == "patrono" else colonna
		var tcs: Dictionary = cs.get(col, cs.get("opportunita", {}))
		if not tcs.is_empty():
			b.condizione = dadi.su_tabella(tcs).riga
		var ln: Dictionary = inc.get("luoghi_notevoli", {})
		var tln: Dictionary = ln.get(col, ln.get("opportunita", {}))
		if not tln.is_empty():
			b.luogo = dadi.su_tabella(tln).riga
	# numero dei nemici
	b.numero = numero_nemici(nem, b)
	# individui unici
	var iu: Dictionary = inc.get("individui_unici", {})
	var q: Dictionary = iu.get("quando", {})
	if not (b.categoria in q.get("esclusi", ["minacce_vaganti"]) or tipo == "invasione") or s.difficolta == "follia":
		var t := dadi.tira("2d6") + (1 if b.categoria == "parti_interessate" else 0) + (1 if s.difficolta == "hardcore" else 0)
		if t >= int(q.get("soglia", 9)) or s.difficolta == "follia":
			var tab: Dictionary = iu.get("tabella", {})
			if not tab.is_empty():
				var u := str(dadi.su_tabella(tab).riga.get("nemico", ""))
				if u != "":
					b.unici.append(u)
	b["descrizione"] = descrivi_battaglia(b)
	s["battaglia"] = b
	s["fase"] = "battaglia"
	scrivi("Battaglia: %s" % b.descrizione, "battaglia")
	return b

func numero_nemici(nem: Dictionary, b: Dictionary) -> int:
	var dim := int(s.get("dimensione", 6))
	var d1 := dadi.d6()
	var d2 := dadi.d6()
	if s.difficolta in ["impegnativo", "hardcore", "follia"]:
		if d1 <= 2:
			d1 = dadi.d6()
		if d2 <= 2:
			d2 = dadi.d6()
	var n := d1
	if dim >= 6:
		n = max(d1, d2)
	elif dim <= 4:
		n = min(d1, d2)
	n += int(nem.get("numeri", 0))
	if b.obiettivo == "difendere":
		n += 1
	if b.tipo == "missione" and s.missione.get("finale", false):
		n += 1
	if b.tipo == "invasione":
		n += 2
	var schierabili: int = min(disponibili().size(), dim)
	if dim - schierabili >= 2:
		n -= 1
	if s.difficolta == "facile" and n >= 5:
		n -= 1
	if s.difficolta in ["hardcore", "follia"]:
		n += 1
	var ce: Dictionary = b.get("condizione", {}).get("effetti", {})
	if ce.has("nemici_mod"):
		n += int(ce.nemici_mod)
	if b.get("zona_rossa", false):
		n = max(n, 7 + int(nem.get("numeri", 0)))
	return max(1, n)

func descrivi_battaglia(b: Dictionary) -> String:
	var nem := Dati.nemico(str(b.nemico))
	var t := "%s contro %d %s" % [{"opportunita": "Missione d'Opportunità", "patrono": "Lavoro per un Patrono", "missione": "Missione",
		"attacca_rivale": "Attacco a un Rivale", "rivale": "Attacco di un Rivale", "invasione": "Battaglia d'Invasione",
		"zona_rossa": "Lavoro in Zona Rossa"}.get(b.tipo, b.tipo), int(b.numero), str(nem.get("nome", b.nemico))]
	t += ". Obiettivo: %s." % nome_obiettivo(str(b.obiettivo))
	if not b.condizione.is_empty() and str(b.condizione.get("id", "")) != "nessuna":
		t += " Condizione: %s." % b.condizione.get("nome", "")
	if not b.luogo.is_empty() and str(b.luogo.get("id", "")) != "niente":
		t += " Luogo notevole: %s." % b.luogo.get("nome", "")
	for u in b.unici:
		t += " Con un Individuo Unico: %s." % Dati.nemico(str(u)).get("nome", u)
	return t

## ===================== dopo la battaglia =====================

## esito = {"vinto": bool, "campo": bool (tenuto il campo), "perdite": [id personaggi diventati vittime],
##  "partecipanti": [id], "primo": id, "unico_ucciso": id o "", "fuggiti_presto": [id], "nemici_uccisi": n}
func dopo_battaglia(esito: Dictionary) -> void:
	var b: Dictionary = s.battaglia
	s["esito"] = esito
	s["statistiche"]["battaglie"] = int(s.statistiche.battaglie) + 1
	if esito.get("vinto", false):
		s["statistiche"]["vittorie"] = int(s.statistiche.vittorie) + 1
	scrivi("Esito: %s%s." % ["Vittoria" if esito.get("vinto", false) else "Sconfitta", ", avete tenuto il campo" if esito.get("campo", false) else ""], "titolo")
	var nem := Dati.nemico(str(b.get("nemico", "")))
	var cat := str(nem.get("categoria", ""))
	var pb: Dictionary = Dati.f("post_battaglia")
	# 1. rivali
	if b.tipo != "invasione" and cat != "minacce_vaganti":
		if b.get("rivale", "") != "":
			if esito.get("campo", false):
				var t := dadi.d6() + (1 if _rivale(b.rivale).get("rintracciato", false) else 0) + (1 if esito.get("unico_ucciso", "") != "" else 0)
				if t >= 4:
					s["rivali"] = s.rivali.filter(func(r): return r.id != b.rivale)
					scrivi("Il Rivale ne ha avuto abbastanza: non vi darà più fastidio (tiro %d)." % t)
				else:
					scrivi("Il Rivale non si arrende (tiro %d)." % t)
		elif esito.get("campo", false):
			var t := dadi.d6()
			if cat == "elementi_criminali":
				var t2 := dadi.d6()
				if t == 1 or t2 == 1:
					aggiungi_rivale("sconfitti ma vendicativi", str(b.nemico))
			elif t == 1:
				aggiungi_rivale("sconfitti ma vendicativi", str(b.nemico))
	for r in s.rivali:
		r["rintracciato"] = false
	# 2. patroni
	var pagato_patrono := 0
	if b.tipo == "patrono" and not s.lavoro.is_empty():
		pagato_patrono = dadi.tira(s.lavoro.get("paga_pericolo", 1))
		if esito.get("vinto", false):
			scrivi("Il lavoro per %s è riuscito." % s.lavoro.patrono, "patrono")
			for e in s.lavoro.get("extra", []):
				if e.categoria == "benefici":
					applica(e.get("effetti", {}), {}, e.nome)
		else:
			scrivi("Il lavoro per %s è fallito." % s.lavoro.patrono, "patrono")
		if not s.lavoro.get("persistente", false):
			s["lavoro"] = {}
		else:
			s["lavoro"] = {}
	# 3. missione
	if b.tipo == "missione" and not s.missione.is_empty():
		if s.missione.get("finale", false):
			if esito.get("vinto", false):
				scrivi("MISSIONE COMPIUTA!", "missione")
				for p in vivi():
					if p.id in esito.get("partecipanti", []):
						Personaggio.modifica_stat(p, "xp", 1)
				s["missione"] = {}
				s["dicerie_missione"] = 0
				applica({"oggetti": ["bottino"], "punti_storia": 1}, {}, "ricompensa della Missione")
		else:
			var t := dadi.d6() + int(s.get("dicerie_missione", 0)) - (0 if esito.get("vinto", false) else 2)
			var r: Dictionary = Dadi.riga(pb.get("missioni", {}).get("tabella", {}), t)
			scrivi("Progresso della Missione (%d): %s - %s" % [t, r.get("nome", ""), r.get("testo", "")], "missione")
			if r.get("effetti", {}).get("missione_finale", false):
				s["missione"]["finale"] = true
			else:
				applica(r.get("effetti", {}), {}, "Missione")
	# 4. paga
	if b.tipo != "invasione":
		var p := dadi.d6()
		if b.tipo == "missione" and esito.get("vinto", false) and not s.missione.is_empty() == false:
			p = max(p, dadi.d6()) + 1
		if esito.get("vinto", false) and b.tipo != "attacca_rivale" and b.tipo != "rivale" and p <= 2:
			p = 3
		if s.difficolta == "facile":
			p += 1
		p += pagato_patrono
		if b.get("zona_rossa", false):
			p += 3
		s["crediti"] = int(s.crediti) + p
		scrivi("Paga: %d crediti%s." % [p, (" (di cui %d di paga di pericolo)" % pagato_patrono) if pagato_patrono > 0 else ""])
		if cat == "elementi_criminali" and esito.get("campo", false):
			var tg := dadi.d6()
			if tg <= 3:
				s["crediti"] = int(s.crediti) + tg
				scrivi("Taglia sui criminali: %d crediti." % tg)
	# 5. ritrovamenti sul campo
	var prova_inv := 0
	if esito.get("campo", false):
		var r := dadi.su_tabella(pb.get("ritrovamenti", {}))
		scrivi("Ritrovamenti sul campo (%d): %s - %s" % [r.tiro, r.riga.get("nome", ""), r.riga.get("testo", "")], "evento")
		if nem.get("speciali", {}).get("minaccia_invasione", false) and r.riga.has("se_minaccia_invasione"):
			applica(r.riga.se_minaccia_invasione, {}, "ritrovamenti")
			prova_inv = 1
		elif str(r.riga.get("nome", "")) == "Arma":
			var arma := ""
			var ar = nem.get("armi", [])
			if ar is Array and not ar.is_empty():
				arma = str(ar[0])
			else:
				arma = str(dadi.scegli(["fucile_militare", "pistola", "fucile_coloniale", "lama", "fucile_pompa"]))
			_aggiungi_al_deposito({"id": arma}, "arma di un nemico caduto")
		else:
			applica(r.riga.get("effetti", {}), {}, str(r.riga.get("nome", "")))
	# 6. invasione
	if nem.get("speciali", {}).get("minaccia_invasione", false) or str(nem.get("regole", "")).to_lower().contains("minaccia d'invasione"):
		var t := dadi.tira("2d6") + prova_inv - (1 if esito.get("campo", false) else 0) + int(s.mondo.get("mod_invasione", 0))
		t += {"hardcore": 2, "follia": 3}.get(s.difficolta, 0)
		if t >= 9:
			s["mondo"]["invasione_imminente"] = true
			scrivi("Controllo dell'Invasione: %d. Il mondo sta per essere invaso! Al prossimo turno dovrete fuggire." % t, "pericolo")
		else:
			scrivi("Controllo dell'Invasione: %d, nessuna invasione." % t)
	if b.tipo == "invasione":
		s["flag"].erase("battaglia_invasione")
		s["mondo"]["invasione_imminente"] = false
		s["pianeti_invasi"].append({"nome": s.mondo.nome, "mod": 0})
		scrivi("Lasciate il mondo invaso al prossimo viaggio.")
		s["mondo"]["invaso"] = true
	# 7. bottino
	if esito.get("campo", false) and b.tipo != "invasione":
		var n := 1
		if b.get("zona_rossa", false):
			n = 2
		for i in n:
			_aggiungi_al_deposito(tira_bottino("bottino"), "bottino")
	# 8. ferite
	for id in esito.get("perdite", []):
		var pg := trova(str(id))
		if pg.is_empty() or pg.get("morto", false):
			continue
		ferisci(pg)
	# 9. esperienza
	var xp: Dictionary = pb.get("esperienza", {}).get("tabella", {})
	for id in esito.get("partecipanti", []):
		var pg := trova(str(id))
		if pg.is_empty() or pg.get("morto", false) or id in esito.get("fuggiti_presto", []):
			continue
		var n := 0
		if id in esito.get("perdite", []):
			n = int(xp.get("ferito", 1))
		elif esito.get("vinto", false):
			n = int(xp.get("sopravvissuto_vinto", 3))
		else:
			n = int(xp.get("sopravvissuto_non_vinto", 2))
		if esito.get("primo", "") == id:
			n += int(xp.get("primo_a_infliggere_vittima", 1))
		if esito.get("unico_ucciso", "") == id:
			n += int(xp.get("ucciso_individuo_unico", 1))
		if s.difficolta == "facile":
			n += 1
		pg["battaglie"] = int(pg.get("battaglie", 0)) + 1
		if not Personaggio.bonus(pg, "no_xp", false):
			Personaggio.modifica_stat(pg, "xp", n)
			scrivi("%s: +%d XP (totale %d)." % [pg.nome, n, pg.xp])
	# punti storia: giorno amaro
	var morto := false
	for id in esito.get("perdite", []):
		if trova(str(id)).get("morto", false):
			morto = true
	if morto and esito.get("campo", false):
		applica({"punti_storia": 1}, {}, "un giorno amaro")
	# traccia della storia
	if s.storia.get("attiva", false) and not s.storia.get("in_corso", false):
		var o := int(s.storia.orologio)
		if esito.get("vinto", false):
			o -= 1
		else:
			var t := dadi.d6()
			o -= 0 if t == 1 else (2 if t == 6 else 1)
		s["storia"]["orologio"] = max(0, o)
		scrivi("Orologio della Storia: %d." % s.storia.orologio)
	if s.storia.get("in_corso", false):
		s["storia"]["in_corso"] = false
		if esito.get("vinto", false):
			s["storia"]["evento"] = int(s.storia.evento) + 1
			s["storia"]["orologio"] = 5
			scrivi("Evento della Storia completato.", "missione")
	s["fase"] = "acquisti"

func _rivale(id: String) -> Dictionary:
	for r in s.rivali:
		if r.id == id:
			return r
	return {}

## Tiro sulla tabella delle ferite (o dei danni dei Bot) per un personaggio diventato vittima.
func ferisci(pg: Dictionary) -> void:
	var pb: Dictionary = Dati.f("post_battaglia")
	var bot := Personaggio.e_robot(pg) or bool(Personaggio.bonus(pg, "ferite_bot", false))
	var tab: Dictionary = pb.get("ferite_bot" if bot else "ferite", {})
	var r := dadi.su_tabella(tab)
	var eff: Dictionary = r.riga.get("effetti", {}).duplicate(true)
	scrivi("Ferite di %s (%d): %s - %s" % [pg.nome, r.tiro, r.riga.get("nome", ""), r.riga.get("testo", "")], "ferita")
	if eff.get("morte", false) and int(pg.get("fortuna", 0)) > 0:
		scrivi("%s sopravvive miracolosamente, ma perde tutta la Fortuna." % pg.nome)
		pg["fortuna"] = 0
		eff.erase("morte")
		eff.erase("rimosso")
		eff["turni_recupero"] = "1d6"
	if eff.get("morte", false) and pg.get("specie") == "recluta_speranzosa":
		pass
	applica(eff, pg, str(r.riga.get("nome", "")))

## Miglioramento di una statistica con gli XP (o con i crediti per i Bot). Restituisce true se riuscito.
func migliora(pg: Dictionary, stat: String) -> bool:
	var au: Dictionary = Dati.f("post_battaglia").get("aumenti", {}).get("statistiche", {}).get(stat, {})
	if au.is_empty():
		return false
	var costo := int(au.get("costo_xp", 99))
	if int(pg.get(stat, 0)) >= Personaggio.massimo(pg, stat):
		return false
	if Personaggio.bonus(pg, "upgrade_crediti", false) or Personaggio.e_robot(pg):
		if stat in pg.get("potenziamenti", []) or int(s.crediti) < costo:
			return false
		s["crediti"] = int(s.crediti) - costo
		pg["potenziamenti"].append(stat)
	else:
		if int(pg.xp) < costo:
			return false
		pg["xp"] = int(pg.xp) - costo
	pg[stat] = int(pg[stat]) + 1
	scrivi("%s migliora %s a %d." % [pg.nome, Personaggio.nome_stat(stat), int(pg[stat])])
	return true

func miglioramenti_possibili(pg: Dictionary) -> Array:
	var r := []
	var stats: Dictionary = Dati.f("post_battaglia").get("aumenti", {}).get("statistiche", {})
	for st in stats:
		var costo := int(stats[st].get("costo_xp", 99))
		if int(pg.get(st, 0)) >= Personaggio.massimo(pg, st):
			continue
		if Personaggio.e_robot(pg):
			if not st in pg.get("potenziamenti", []) and int(s.crediti) >= costo:
				r.append(st)
		elif int(pg.get("xp", 0)) >= costo:
			r.append(st)
	return r

## Acquisto: tabella ("arma_militare", "equip", "gadget") per 3 crediti o arma economica per 1 credito.
func compra(cosa: String) -> bool:
	var acq: Array = Dati.f("post_battaglia").get("acquisti", {}).get("regole", [])
	var economiche := ["pistola", "lama", "fucile_coloniale", "fucile_pompa"]
	var costo := 1 if cosa in economiche else 3
	if int(s.crediti) < costo:
		return false
	s["crediti"] = int(s.crediti) - costo
	if cosa in economiche:
		_aggiungi_al_deposito({"id": cosa}, "acquisto")
	else:
		_aggiungi_al_deposito(tira_oggetto(cosa), "acquisto")
	return true

func vendi(da_pg: String, indice: int) -> void:
	var sorg: Array = s.deposito if da_pg == "" else trova(da_pg).get("oggetti", [])
	if indice < 0 or indice >= sorg.size():
		return
	var o = sorg[indice]
	if o.get("danneggiato", false):
		return
	sorg.remove_at(indice)
	s["crediti"] = int(s.crediti) + 1
	scrivi("Venduto %s per 1 credito." % Dati.nome_oggetto(str(o.id)))

## Addestramento avanzato: iscrizione e corso.
func addestramento(pg: Dictionary, corso_id: String) -> bool:
	var aa: Dictionary = Dati.f("post_battaglia").get("addestramento_avanzato", {})
	if pg.has("corso") or int(s.crediti) < 1:
		return false
	var corso := {}
	for c in aa.get("corsi", []):
		if c.get("id") == corso_id:
			corso = c
	if corso.is_empty():
		return false
	var costo := int(corso.get("costo", 20))
	if int(pg.get("xp", 0)) + int(s.crediti) - 1 < costo:
		return false
	s["crediti"] = int(s.crediti) - 1
	var t := dadi.tira("2d6")
	if t < 4:
		scrivi("%s non viene ammesso al corso (tiro %d)." % [pg.nome, t])
		return false
	var da_xp: int = min(int(pg.get("xp", 0)), costo)
	pg["xp"] = int(pg.xp) - da_xp
	s["crediti"] = int(s.crediti) - (costo - da_xp)
	pg["corso"] = corso_id
	scrivi("%s completa il corso: %s. %s" % [pg.nome, corso.get("nome", ""), corso.get("testo", "")])
	return true

## Eventi di fine turno: evento della campagna, evento del personaggio, guerra galattica.
func passo_eventi() -> void:
	var pb: Dictionary = Dati.f("post_battaglia")
	if not s.flag.get("niente_eventi", false):
		var r := dadi.su_tabella(pb.get("eventi_campagna", {}))
		scrivi("Evento della campagna (%d): %s - %s" % [r.tiro, r.riga.get("nome", ""), r.riga.get("testo", "")], "evento")
		applica(r.riga.get("effetti", {}), {}, str(r.riga.get("nome", "")))
		var cand := []
		for p in vivi():
			if not Personaggio.bonus(p, "no_eventi_personaggio", false) and not p.get("assente", false):
				cand.append(p)
		if not cand.is_empty():
			var pg: Dictionary = dadi.scegli(cand)
			var r2 := dadi.su_tabella(pb.get("eventi_personaggio", {}))
			var esclusi: Array = r2.riga.get("esclusi", [])
			if pg.get("specie") in esclusi.map(func(x): return id_specie(str(x))):
				scrivi("Evento del personaggio per %s: %s, ma non lo riguarda." % [pg.nome, r2.riga.get("nome", "")])
			else:
				scrivi("Evento del personaggio per %s (%d): %s - %s" % [pg.nome, r2.tiro, r2.riga.get("nome", ""), r2.riga.get("testo", "")], "evento")
				applica(r2.riga.get("effetti", {}), pg, str(r2.riga.get("nome", "")))
	# guerra galattica
	for pi in s.get("pianeti_invasi", []):
		if pi.get("finito", false):
			continue
		var t := dadi.tira("2d6") + int(pi.get("mod", 0))
		var r: Dictionary = Dadi.riga(pb.get("guerra_galattica", {}), t)
		scrivi("Guerra galattica su %s (%d): %s." % [pi.nome, t, r.get("nome", "")])
		var e: Dictionary = r.get("effetti", {})
		if e.has("mod_guerra"):
			pi["mod"] = int(pi.get("mod", 0)) + 1
		if e.get("pianeta_perso", false) or e.get("pianeta_liberato", false):
			pi["finito"] = true
	s["flag"].erase("niente_eventi")
	s["fase"] = "fine"

func fine_turno() -> void:
	for p in vivi():
		p["fortuna"] = max(int(p.get("fortuna", 0)), int(p.get("fortuna_iniziale", p.get("fortuna", 0))))
	s["fase"] = "inizio_turno"

## Condizione di sconfitta della campagna: nessuno vivo.
func finita() -> bool:
	return vivi().is_empty()
