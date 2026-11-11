# WS_Copy


## BASE Framework erweitern

### FRAMEWORK

```
ID: ws_abstract_short
Name: Kurzabstract
Beschreibung: Kurze Zusammenfassung des Textes

Fragment:
<abstract xmlns="http://www.tei-c.org/ns/1.0" type="short"><p></p></abstract>

Operation:
InsertFragmentOperation

Vorgänge:
1)
XPath-Aktivierung: //teiHeader/profileDesc[correspDesc and not(abstract[@type='short'])]
insertLocation: //profileDesc/correspDesc
insertPosition: After

2.)
XPath-Aktivierung: //teiHeader/profileDesc[creation and not(abstract[@type='short'])]
insertLocation: //profileDesc/creation
insertPosition: After

3.)
XPath-Aktivierung: //teiHeader/profileDesc/abstract[not(@type="short")]
insertLocation: //profileDesc/abstract
insertPosition: After

4.)
XPath-Aktivierung: //teiHeader/profileDesc[not(abstract[@type='short'])]
insertLocation: //profileDesc
insertPosition: Inside as first child

```

=> In Toolbar einfügen. (Eigener Ordner "Workshop".)


### CSS
- Neuer Ordner: `css` mit Datei "standard.css".
- Einstellungen:
    - `${framework}/css/standard.css`
    - `Standardansicht`

```
abstract[type="short"]{
	font-size: smaller;
}
abstract[type="short"]:before{
	content: "Kurzabstract: ";
}
```


### SCHEMA

Bei `<element name="abstract">` einfügen:
```
         <optional>
            <attribute name="type">
               <value>short</value>
            </attribute>
         </optional>
```


#############################################

## Journale

### SCHEMA

In `<TEI>` einfügen:
```
         <attribute name="doctype" ns="http://www.telota.de">
            <choice>
               <value>letter</value>
               <value>document</value>
               <value>journal</value>
               <value>adjutantenjournal</value>
            </choice>
         </attribute>
```


### CSS

```css
/* 1. Durchgang */
TEI[*|doctype="adjutantenjournal"] div[type='tag'] {
    margin: 1em;
    background-color: #ecf5ff;
}

TEI[*|doctype="adjutantenjournal"] dateline date[when]:before {
	content: concat('Datum: ', oxy_xpath('format-date(xs:date(./@when), "[FNn], den [D]. [MNn] [Y]")'))
}
```


### FRAMEWORK - Neuer Eintrag

```
ID: ws_journal_newDate
Name: Neuen Tageseintrag
Beschreibung: Neuen Tageseintrag

1. Vorgang - InsertFragmentOperation
XPath-Aktivierung: ancestor-or-self::text[@type="journal"]/body

fragment:
<div xmlns="http://www.tei-c.org/ns/1.0" type="tag">
  <dateline>
    <date when="${ask('Tagesdatum (Format: JJJJ-MM-TT)')}"/>
  </dateline>
  <div type="journalText">
      <ab type="author"></ab>
      <p></p>
  </div>
</div>

insertLocation: ancestor-or-self::text[@type="journal"]/body
insertPosition: Inside as last child
```

### FRAMEWORK - Adjutant vom Dienst

```
ID: ws_journal_persNameAdjutant
Name: Adjutant vom Dienst eintragen
Beschreibung: Eintragen des Adjutanten vom Dienst.

1. Vorgang - RegisterInsertFragmentOperation
XPath-Aktivierung: ancestor-or-self::div[@type="tag"][.//ab[@type="author"]/not(persName)]

URL: ${ediarum_project_domain}${ediarum_projects_directory}${ediarum_project_name}${ediarum_index_person}
node: //li
namespace: tei:http://www.tei-c.org/ns/1.0
item rendering: $XPATH{/span}
item variable: <persName xmlns='http://www.tei-c.org/ns/1.0'  key='$XPATH{@xml:id}'>$XPATH{/span}</persName>
multiple selection: true
item separator:  [Leerzeichen]
element: $ITEMS
insertLocation: ancestor-or-self::div[@type="tag"]//ab[@type="author"]
insertPosition: Inside as first child
schemaAware: false
```


### FRAMEWORK ÜBUNG - Ort einfügen

```
ID: ws_journal_placeName
Name: Ort einfügen
Beschreibung: Fügt einen Ort zum Adjutantenjournal ein.

1. Vorgang - RegisterInsertFragmentOperation
XPath-Aktivierung: kann leer bleiben

URL: ${ediarum_project_domain}${ediarum_projects_directory}${ediarum_project_name}${ediarum_index_place}
node: //li
namespace: tei:http://www.tei-c.org/ns/1.0
item rendering: $XPATH{/span}
item variable: <placeName xmlns='http://www.tei-c.org/ns/1.0'  key='$XPATH{@xml:id}'>$XPATH{/span}</placeName>
multiple selection: false
item separator:  [Leerzeichen]
element: $ITEMS
insertLocation: ancestor-or-self::div[@type="tag"]/dateline
insertPosition: Inside as last child
schemaAware: true
```

### CSS ÜBUNG

```css
/* LÖSUNG ÜBUNG */
TEI[*|doctype="adjutantenjournal"] div[type='tag'] {
    margin: 1em;
    background-color: #ecf5ff;
}

TEI[*|doctype="adjutantenjournal"] dateline date[when]:before {
    font-weight: bold;
    content: concat('Datum: ', oxy_xpath('format-date(xs:date(./@when), "[FNn], den [D]. [MNn] [Y]")'))
}

TEI[*|doctype="adjutantenjournal"] ab[type="author"]:before {
    content: "Adjutant vom Dienst: ";
}
TEI[*|doctype="adjutantenjournal"] ab[type="author"] {
    font-style: italic;
    padding-bottom: 0.5em;
}

/* Ort einfügen */
TEI[*|doctype="adjutantenjournal"] dateline > placeName:before {
	content: '\aOrt: ';
}

TEI[*|doctype="adjutantenjournal"] dateline > placeName {
	font-style: italic;
	-oxy-editable: false;
}
```


