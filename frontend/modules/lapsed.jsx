'use strict';

const React = require('react');

const Menu = require('./../components/menu-toolbar/menu-toolbar.jsx');

const ArveteSaatmine = require('./../docs/arvete_saatmine/index.jsx');
const ArveteSaatmineDokument = require('./../docs/arvete_saatmine/document/index.jsx');

const JournalDocument = require('../docs/journal/document/index.jsx');

const LapseDokument = require('./../docs/laps/document/index.jsx');
const LasteRegister = require('./../docs/laps/index.jsx');

const LasteTeenustRegister = require('./../docs/lapse_kaart/index.jsx');
const LapseKaartDokument = require('./../docs/lapse_kaart/document/index.jsx');

const AsendusTaabelRegister = require('./../docs/asendus_taabel/index.jsx');
const AsendusTaabelDokument = require('./../docs/asendus_taabel/document/index.jsx');

const LasteTaabelRegister = require('./../docs/lapse_taabel/index.jsx');
const LapseTaabelDokument = require('./../docs/lapse_taabel/document/index.jsx');

const PaevaTaabelRegister = require('./../docs/paeva_taabel/index.jsx');
const PaevaTaabelDokument = require('./../docs/paeva_taabel/document/index.jsx');

const VanemDokument = require('./../docs/vanem/document/index.jsx');
const VanemateRegister = require('./../docs/vanem/index.jsx');

const ArvedeRegister = require('./../docs/arv/index.jsx');
const ArveDocument = require('./../docs/arv/document/index.jsx');

const SmkRegister = require('./../docs/smk/index.jsx');
const SmkDocument = require('./../docs/smk/document/index.jsx');
const VmkRegister = require('./../docs/vmk/index.jsx');
const VmkDocument = require('./../docs/vmk/document/index.jsx');


const SorderideRegister = require('./../docs/sorder/index.jsx');
const SorderDocument = require('./../docs/sorder/document/index.jsx');

const NomRegister = require('./../docs/nomenclature/index.jsx'),
    NomDocument = require('./../docs/nomenclature/document/index.jsx');

const TunnusRegister = require('./../docs/tunnus/index.jsx'),
    TunnusDocument = require('./../docs/tunnus/document/index.jsx');

const AsutusRegister = require('./../docs/asutused/index.jsx'),
    AsutusDocument = require('./../docs/asutused/document/index.jsx');

const LapseGruppRegister = require('./../docs/lapse_grupp/index.jsx'),
    LapseGruppDocument = require('./../docs/lapse_grupp/document/index.jsx');

const TeatisRegister = require('./../docs/teatis/index.jsx'),
    TeatisDocument = require('./../docs/teatis/document/index.jsx');

const AsutuseLiikRegister = require('./../docs/asutuse_liik/index.jsx'),
    AsutuseLiikDocument = require('./../docs/asutuse_liik/document/index.jsx');

const KoolituseTyypRegister = require('./../docs/koolituse_tyyp/index.jsx'),
    KoolituseTyypDocument = require('./../docs/koolituse_tyyp/document/index.jsx');

const KoolituseLiikRegister = require('./../docs/koolituse_liik/index.jsx'),
    KoolituseLiikDocument = require('./../docs/koolituse_liik/document/index.jsx');

const PankVVRegister = require('./../docs/pank_vv/index.jsx');
const PankVVDocument = require('./../docs/pank_vv/document/index.jsx');
const ViitenrDocument = require('./../docs/viitenr/document/index.jsx');

const ConfigDocument = require('./../docs/config/document/index.jsx');
const RekvDocument = require('./../docs/rekv/document/index.jsx');
const DokpropsDocument = require('./../docs/dokprops/document/index.jsx');
const UserDocument = require('./../docs/userid/document/index.jsx');
const EmailDocument = require('./../docs/e-mail/document/index.jsx');

const Inf3Report = require('./../docs/inf3/index.jsx');
const ChildSummaryReport = require('./../docs/child_summary/index.jsx');
const ChildSummaryKaibedReport = require('./../docs/child_summary_kaibed/index.jsx');
const ArvedKoodiJargiReport = require('./../docs/arved_koodi_jargi/index.jsx');
const SaldoJaKaiveReport = require('./../docs/saldo_ja_kaive/index.jsx');
const SaldoJaKaibeAndmik = require('./../docs/saldo_ja_kaibeandmik/index.jsx');
const SaldoJaKaKokku = require('./../docs/saldo_ja_ka_kokku/index.jsx');
const KaiveAruanne = require('./../docs/kaive_aruanne/index.jsx');
const KaiveAruanneKokku = require('./../docs/kaive_aruanne_kokku/index.jsx');
const SentDocsReport = require('./../docs/sent_docs/index.jsx');
const ChildAgeReport = require('./../docs/child_age/index.jsx');
const SoodustusedReport = require('./../docs/soodustused/index.jsx');
const StatistikaReport = require('./../docs/statistika/index.jsx');
const EbatoenaolisedReport = require('./../docs/ebatoenaolised/index.jsx');
const KondArveReport = require('./../docs/kondarve/index.jsx');
const AastaNaitajadReport = require('./../docs/aasta_naitajad/index.jsx');
const KuuTaabel = require('./../docs/kuu_taabel/index.jsx');
const YksuseTaabel = require('./../docs/yksuse_taabel/index.jsx');
const KohalolekuAruanne = require('./../docs/kohaloleku_aruanne/index.jsx');
const Topeltmaksud = require('./../docs/topeltmaksud/index.jsx');
const Kuutabeli_aruanne = require('./../docs/kuutabeli_aruanne/index.jsx');
const Selgemata_maksed = require('./../docs/selgemata_maksed/index.jsx');
const PankEarve = require('./../docs/pank_earve/index.jsx');
const SaldodAsutustes = require('./../docs/saldod_asutustes/index.jsx');

const {Route, Redirect} = require('react-router-dom');

const {StyleRoot} = require('radium');
const MODULE = 'Lapsed';
const DocContext = require('./../doc-context.js');

class App extends React.Component {
    constructor(props) {
        super(props);
        this.prepareParamsForToolbar = this.prepareParamsForToolbar.bind(this);
        this.componets = {};
        this.prepareComponents(this.componets);

    }

    render(history) {
        return (
            <StyleRoot>
                <Route exact path="/lapsed/arvete_saatmine"
                       render={(props) =>
                           <ArveteSaatmine
                               history={props.history}
                               initData={this.props.initData}
                               module={MODULE}/>}
                />
                <Route exact path="/lapsed/arvete_saatmine/:docId"
                       render={(props) => <ArveteSaatmineDokument {...props}
                                                         history={props.history}
                       />}/>

                <Route exact path="/lapsed"
                       render={(props) =>
                           <LasteRegister
                               history={props.history}
                               initData={this.props.initData}
                               module={MODULE}/>}
                />
                <Route exact path="/lapsed/laps"
                       render={(props) => <LasteRegister history={props.history}
                                                         initData={this.props.initData}
                                                         handleRouting={this.handleRouting}
                                                         module={MODULE}/>}
                />

                <Route exact path="/lapsed/laps/:docId"
                       render={(props) => <LapseDokument {...props}
                                                         history={props.history}
                       />}/>

                <Route exact path="/lapsed/asutused"
                       render={(props) =>
                           <AsutusRegister
                               history={props.history}
                               initData={this.props.initData}
                               module={MODULE}/>}
                />

                <Route exact path="/lapsed/asutused/:docId"
                       render={(props) => <AsutusDocument  {...props} history={props.history}/>}/>

                <Route exact path="/lapsed/lapse_grupp"
                       render={(props) =>
                           <LapseGruppRegister
                               history={props.history}
                               initData={this.props.initData}
                               module={MODULE}/>}
                />

                <Route exact path="/lapsed/lapse_grupp/:docId"
                       render={(props) => <LapseGruppDocument  {...props} history={props.history}/>}/>

                <Route exact path="/lapsed/vanem"
                       render={(props) => <VanemateRegister history={props.history}
                                                            initData={this.props.initData}
                                                            module={MODULE}/>}/>
                <Route exact path="/lapsed/vanem/:docId"
                       render={(props) => <VanemDokument {...props} history={props.history}/>}/>

                <Route exact path="/lapsed/lapse_kaart"
                       render={(props) => <LasteTeenustRegister history={props.history}
                                                                initData={props.initData}
                                                                module={MODULE}/>}
                />
                <Route exact path="/lapsed/lapse_kaart/:docId" component={LapseKaartDokument}/>

                <Route exact path="/lapsed/asendus_taabel"
                       render={(props) => <AsendusTaabelRegister history={props.history}
                                                               initData={props.initData}
                                                               module={MODULE}/>}/>
                <Route exact path="/lapsed/asendus_taabel/:docId" component={AsendusTaabelDokument}/>

                <Route exact path="/lapsed/lapse_taabel"
                       render={(props) => <LasteTaabelRegister history={props.history}
                                                               initData={props.initData}
                                                               module={MODULE}/>}/>
                <Route exact path="/lapsed/lapse_taabel/:docId" component={LapseTaabelDokument}/>

                <Route exact path="/lapsed/paeva_taabel"
                       render={(props) => <PaevaTaabelRegister history={props.history}
                                                               initData={props.initData}
                                                               module={MODULE}/>}/>
                <Route exact path="/lapsed/paeva_taabel/:docId" component={PaevaTaabelDokument}/>

                <Route exact path="/lapsed/arv"
                       render={(props) => <ArvedeRegister history={props.history}
                                                          initData={props.initData}
                                                          module={MODULE}/>}
                />
                <Route exact path="/lapsed/arv/:docId"
                       render={(props) => <ArveDocument {...props} history={props.history}/>}/>

                <Route exact path="/lapsed/journal/:docId"
                       render={(props) => <JournalDocument {...props} history={props.history}/>}
                />


                <Route exact path="/lapsed/smk"
                       render={(props) => <SmkRegister history={props.history}
                                                       initData={props.initData}
                                                       module={MODULE}/>}/>
                <Route exact path="/lapsed/smk/:docId"
                       render={(props) => <SmkDocument {...props} history={props.history}/>}/>

                <Route exact path="/lapsed/vmk"
                       render={(props) => <VmkRegister history={props.history}
                                                       initData={props.initData}
                                                       module={MODULE}/>}/>
                <Route exact path="/lapsed/vmk/:docId"
                       render={(props) => <VmkDocument {...props}
                                                       history={props.history}/>}/>


                <Route exact path="/lapsed/sorder"
                       render={(props) =>
                           <SorderideRegister
                               history={props.history}
                               initData={props.initData}
                               module={MODULE}/>}
                />
                <Route exact path="/lapsed/sorder/:docId"
                       render={(props) => <SorderDocument {...props} history={props.history}/>}/>


                <Route exact path="/lapsed/nomenclature"
                       render={(props) => <NomRegister history={props.history}
                                                       initData={props.initData}
                                                       module={MODULE}/>}/>
                <Route exact path="/lapsed/nomenclature/:docId"
                       render={(props) => <NomDocument {...props}
                                                       module={MODULE}
                                                       history={props.history}
                       />}/>

                <Route exact path="/lapsed/tunnus/:docId" component={TunnusDocument}/>
                <Route exact path="/lapsed/tunnus"
                       render={(props) => <TunnusRegister
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>

                <Route exact path="/lapsed/teatis/:docId" component={TeatisDocument}/>
                <Route exact path="/lapsed/teatis"
                       render={(props) => <TeatisRegister
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>

                <Route exact path="/lapsed/pank_vv/:docId" component={PankVVDocument}/>
                <Route exact path="/lapsed/pank_vv"
                       render={(props) => <PankVVRegister
                           module={MODULE}
                           history={props.history}
                           initData={this.props.initData}/>}/>

                <Route exact path="/lapsed/config/:docId"
                       render={(props) => <ConfigDocument {...props} history={props.history}/>}/>
                <Route exact path="/lapsed/config"
                       render={() => <Redirect to={`/lapsed/config/${DocContext.userData.asutusId}`}/>}/>

                <Route exact path="/lapsed/e-mail/:docId"
                       render={(props) => <EmailDocument {...props} history={props.history}/>}/>
                <Route exact path="/lapsed/e-mail"
                       render={() => <Redirect to={`/lapsed/e-mail/0`}/>}/>

                <Route exact path="/lapsed/rekv/:docId"
                       render={(props) => <RekvDocument {...props} history={props.history}/>}/>

                <Route exact path="/lapsed/rekv"
                       render={() => <Redirect to={`/lapsed/rekv/${DocContext.userData.asutusId}`}/>}/>

                <Route exact path="/lapsed/dokprops/:docId"
                       render={(props) => <DokpropsDocument {...props} history={props.history}/>}/>

                <Route exact path="/lapsed/userid/:docId"
                       render={(props) => <UserDocument {...props} history={props.history}/>}/>
                <Route exact path="/lapsed/userid/"
                       render={() => <Redirect to={`/lapsed/userid/${DocContext.userData.id}`}/>}/>

                <Route exact path="/lapsed/inf3"
                       render={(props) => <Inf3Report
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>

                <Route exact path="/lapsed/laps_kokkuvotte"
                       render={(props) => <ChildSummaryReport
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>

                <Route exact path="/lapsed/laps_kv_kaibed"
                       render={(props) => <ChildSummaryKaibedReport
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>

                <Route exact path="/lapsed/arved_koodi_jargi"
                       render={(props) => <ArvedKoodiJargiReport
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>

                <Route exact path="/lapsed/saldo_ja_kaive"
                       render={(props) => <SaldoJaKaiveReport
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>

                <Route exact path="/lapsed/kaive_aruanne"
                       render={(props) => <KaiveAruanne
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>
                <Route exact path="/lapsed/kaive_aruanne_kokku"
                       render={(props) => <KaiveAruanneKokku
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>
                <Route exact path="/lapsed/saldo_ja_kaibeandmik"
                       render={(props) => <SaldoJaKaibeAndmik
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>
                <Route exact path="/lapsed/saldo_ja_ka_kokku"
                       render={(props) => <SaldoJaKaKokku
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>

                <Route exact path="/lapsed/sent_docs"
                       render={(props) => <SentDocsReport
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>

                <Route exact path="/lapsed/child_age"
                       render={(props) => <ChildAgeReport
                           module={MODULE}
                           history={props.history}
                           initData={this.props.initData}/>}/>
                <Route exact path="/lapsed/soodustused"
                       render={(props) => <SoodustusedReport
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>
                <Route exact path="/lapsed/statistika"
                       render={(props) => <StatistikaReport
                           module={MODULE}
                           history={props.history}
                           initData={this.props.initData}/>}/>
                <Route exact path="/lapsed/ebatoenaolised"
                       render={(props) => <EbatoenaolisedReport
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>
                <Route exact path="/lapsed/kondarve"
                       render={(props) => <KondArveReport
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>
                <Route exact path="/lapsed/aasta_naitajad"
                       render={(props) => <AastaNaitajadReport
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>
                <Route exact path="/lapsed/kuu_taabel"
                       render={(props) => <KuuTaabel
                           module={MODULE}
                           history={props.history}
                           initData={this.props.initData}/>}/>
                <Route exact path="/lapsed/yksuse_taabel"
                       render={(props) => <YksuseTaabel
                           module={MODULE}
                           history={props.history}
                           initData={this.props.initData}/>}/>
                <Route exact path="/lapsed/kohaloleku_aruanne"
                       render={(props) => <KohalolekuAruanne
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>
                <Route exact path="/lapsed/topeltmaksud"
                       render={(props) => <Topeltmaksud
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>

                <Route exact path="/lapsed/kuutabeli_aruanne"
                       render={(props) => <Kuutabeli_aruanne
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>

                <Route exact path="/lapsed/selgemata_maksed"
                       render={(props) => <Selgemata_maksed
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>

                <Route exact path="/lapsed/pank_earve"
                       render={(props) => <PankEarve
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>

                <Route exact path="/lapsed/saldod_asutustes"
                       render={(props) => <SaldodAsutustes
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>

                <Route exact path="/lapsed/asutuse_liik"
                       render={(props) => <AsutuseLiikRegister
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>
                <Route exact path="/lapsed/asutuse_liik/:docId"
                       render={(props) => <AsutuseLiikDocument {...props}
                                                               module={MODULE}
                                                               history={props.history}
                       />}/>
                <Route exact path="/lapsed/koolituse_tyyp"
                       render={(props) => <KoolituseTyypRegister
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>
                <Route exact path="/lapsed/koolituse_tyyp/:docId"
                       render={(props) => <KoolituseTyypDocument {...props}
                                                                 module={MODULE}
                                                                 history={props.history}
                       />}/>
                <Route exact path="/lapsed/koolituse_liik"
                       render={(props) => <KoolituseLiikRegister
                           module={MODULE}
                           history={props.history}
                           initData={props.initData}/>}/>
                <Route exact path="/lapsed/koolituse_Liik/:docId"
                       render={(props) => <KoolituseLiikDocument {...props}
                                                                 module={MODULE}
                                                                 history={props.history}
                       />}/>
                <Route exact path="/lapsed/viitenr/:docId"
                       render={(props) => <ViitenrDocument {...props}
                                                           module={MODULE}
                                                           history={props.history}
                       />}/>


            </StyleRoot>
        )
    }


    prepareParamsForToolbar() {
        return {
            btnStart: {
                show: true
            },
            btnLogin: {
                show: true,
                disabled: false
            },
            btnAccount: {
                show: true,
                disabled: false
            }

        };
    }

    prepareComponents(components) {
        return components['LapseDocument'] = (props) => {
            const LapseDocument = require('./../docs/laps/document/index.jsx');
            return <LapseDocument {...props}/>
        };
    }


}

module.exports = App;