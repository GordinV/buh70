'use strict';

const React = require('react');

const Menu = require('./../components/menu-toolbar/menu-toolbar.jsx');

const LapseDokument = require('./../docs/laps/document/index.jsx');
const LasteRegister = require('./../docs/laps/index.jsx');

const LasteTeenustRegister = require('./../docs/lapse_kaart/index.jsx');
const LapseKaartDokument = require('./../docs/lapse_kaart/document/index.jsx');

const LasteTaabelRegister = require('./../docs/lapse_taabel/index.jsx');
const LapseTaabelDokument = require('./../docs/lapse_taabel/document/index.jsx');

const VanemDokument = require('./../docs/vanem/document/index.jsx');
const VanemateRegister = require('./../docs/vanem/index.jsx');

const ArvedeRegister = require('./../docs/arv/index.jsx');
const ArveDocument = require('./../docs/arv/document/index.jsx');

const SmkRegister = require('./../docs/smk/index.jsx');
const SmkDocument = require('./../docs/smk/document/index.jsx');

const SorderideRegister = require('./../docs/sorder/index.jsx');
const SorderDocument = require('./../docs/sorder/document/index.jsx');

const AsutusRegister = require('./../docs/asutused/index.jsx'),
    AsutusDocument = require('./../docs/asutused/document/index.jsx');

const NomRegister = require('./../docs/nomenclature/index.jsx'),
    NomDocument = require('./../docs/nomenclature/document/index.jsx');

const TunnusRegister = require('./../docs/tunnus/index.jsx'),
    TunnusDocument = require('./../docs/tunnus/document/index.jsx');


const {Route, withRouter, Redirect} = require('react-router-dom');
const {StyleRoot} = require('radium');
const MODULE = 'Lapsed';


class App extends React.Component {
    constructor(props) {
        super(props);
        this.prepareParamsForToolbar = this.prepareParamsForToolbar.bind(this);
        this.state = {
            userData: this.props.userData
        };
        this.componets = {};
        this.prepareComponents(this.componets);
    }

    render() {
        const context = {};
        let btnParams = this.prepareParamsForToolbar();

        return (
            <StyleRoot>
                <Route path="/lapsed"
                       render={() => <Menu params={btnParams} userData={this.state.userData} module={MODULE}/>}/>

                <Route exact path="/lapsed"
                       render={(props) =>
                           <LasteRegister
                               history={props.history}
                               userData={this.props.userData}
                               initData={this.props.initData}
                               module={MODULE}/>}
                />
                <Route exact path="/lapsed/laps"
                       render={(props) => <LasteRegister history={props.history} userData={this.props.userData}
                                                         initData={this.props.initData} module={MODULE}/>}/>

                <Route exact path="/lapsed/laps/:docId" component={LapseDokument}/>
                <Route exact path="/lapsed/vanem"
                       render={(props) => <VanemateRegister history={props.history} userData={this.props.userData}
                                                            initData={this.props.initData} module={MODULE}/>}/>
                <Route exact path="/lapsed/vanem/:docId" component={VanemDokument}/>

                <Route exact path="/lapsed/lapse_kaart"
                       render={(props) => <LasteTeenustRegister history={props.history}
                                                                userData={this.props.userData}
                                                                initData={this.props.initData} module={MODULE}/>}/>
                <Route exact path="/lapsed/lapse_kaart/:docId" component={LapseKaartDokument}/>

                <Route exact path="/lapsed/lapse_taabel"
                       render={(props) => <LasteTaabelRegister history={props.history}
                                                               userData={this.props.userData}
                                                               initData={this.props.initData} module={MODULE}/>}/>
                <Route exact path="/lapsed/lapse_taabel/:docId" component={LapseTaabelDokument}/>

                <Route exact path="/lapsed/arv"
                       render={(props) => <ArvedeRegister history={props.history} userData={this.props.userData}
                                                          initData={this.props.initData} module={MODULE}/>}/>
                <Route exact path="/lapsed/arv/:docId" component={ArveDocument}/>

                <Route exact path="/lapsed/smk"
                       render={(props) => <SmkRegister history={props.history} userData={this.props.userData}
                                                       initData={this.props.initData} module={MODULE}/>}/>
                <Route exact path="/lapsed/smk/:docId" component={SmkDocument}/>

                <Route exact path="/lapsed/sorder"
                       render={(props) =>
                           <SorderideRegister
                               history={props.history}
                               userData={this.props.userData}
                               initData={this.props.initData}
                               module={MODULE}/>}
                />
                <Route exact path="/lapsed/sorder/:docId" component={SorderDocument}/>

                <Route exact path="/lapsed/asutused/:docId" component={AsutusDocument} module={MODULE}/>
                <Route exact path="/lapsed/asutused"
                       render={(props) =>
                           <AsutusRegister history={props.history}
                                           userData={this.props.userData}
                                           initData={this.props.initData}
                                           module={MODULE}/>}/>

                <Route exact path="/lapsed/nomenclature"
                       render={(props) => <NomRegister history={props.history} userData={this.props.userData}
                                                       initData={this.props.initData} module={MODULE}/>}/>
                <Route exact path="/lapsed/nomenclature/:docId" component={NomDocument}/>

                <Route exact path="/lapsed/tunnus/:docId" component={TunnusDocument}/>
                <Route exact path="/lapsed/tunnus"
                       render={(props) => <TunnusRegister
                           module={MODULE}
                           history={props.history}
                           userData={this.props.userData}
                           initData={this.props.initData}/>}/>

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