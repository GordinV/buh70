'use strict';

const React = require('react');
const PropTypes = require('prop-types');

const JournalRegister = require('./../docs/journal/index.jsx');
const JournalDocument = require('../docs/journal/document/index.jsx');
const ArvedeRegister = require('./../docs/arv/index.jsx');
const ArveDocument = require('./../docs/arv/document/index.jsx');
const SorderideRegister = require('./../docs/sorder/index.jsx');
const SorderDocument = require('./../docs/sorder/document/index.jsx');
const VorderideRegister = require('./../docs/vorder/index.jsx');
const VorderDocument = require('./../docs/vorder/document/index.jsx');
const SmkRegister = require('./../docs/smk/index.jsx');
const SmkDocument = require('./../docs/smk/document/index.jsx');
const VmkDocument = require('./../docs/vmk/document/index.jsx');
const VmkRegister = require('./../docs/vmk/index.jsx');
const Menu = require('./../components/menu-toolbar/menu-toolbar.jsx');
const StartMenu = require('./../components/start-menu/start-menu.jsx'),
    AsutusRegister = require('./../docs/asutused/index.jsx'),
    AsutusDocument = require('./../docs/asutused/document/index.jsx'),
    KontoRegister = require('./../docs/kontod/index.jsx'),
    KontoDocument = require('./../docs/kontod/document/index.jsx'),
    NomRegister = require('./../docs/nomenclature/index.jsx'),
    NomDocument = require('./../docs/nomenclature/document/index.jsx'),
    ProjectRegister = require('./../docs/project/index.jsx'),
    ProjectDocument = require('./../docs/project/document/index.jsx'),
    TunnusRegister = require('./../docs/tunnus/index.jsx'),
    TunnusDocument = require('./../docs/tunnus/document/index.jsx'),
    DocumentLibRegister = require('./../docs/dok/index.jsx'),
    DocumentLibDocument = require('./../docs/dok/document/index.jsx');

const Docs = require('./../docs/dok/index.jsx');

const {Route, withRouter} = require('react-router-dom');
const {StyleRoot} = require('radium');

/*

const HOC = (comp) => (<comp/>);

module.exports =  withRouter(HOC);


*/

class App extends React.Component {
    constructor(props) {
        super(props);
        this.prepareParamsForToolbar = this.prepareParamsForToolbar.bind(this);
        this.componets = {};
        this.prepareComponents(this.componets);
        this.state = {
            userData: this.props.userData
        };

    }

    render() {
        const context = {};
        let activeStyle = {backgroundColor: 'lightblue'};
        let btnParams = this.prepareParamsForToolbar();
        console.log('called render', this.state.userData);
        return (
            <StyleRoot>
                <Route  path="/raama"
                        render={() => <Menu params = {btnParams} userData={this.state.userData}/>}/>
                <Route exact path="/raama"
                       render={(props) => <Docs history = {props.history} userData={this.props.userData} initData={this.props.initData}/>}/>
                <Route exact path="/raama/docs"
                       render={(props) => <Docs history = {props.history} userData={this.props.userData} initData={this.props.initData}/>}/>
                <Route exact path="/raama/dok"
                       render={(props) => <Docs history = {props.history} userData={this.props.userData} initData={this.props.initData}/>}/>
                <Route exact path="/raama/arv/:docId" component = {ArveDocument} />
                <Route exact path="/raama/arv"
                       render={(props) => <ArvedeRegister history = {props.history} userData={this.props.userData} initData={this.props.initData}/>}/>
                <Route exact path="/raama/asutused/:docId" component = {AsutusDocument} />
                <Route exact path="/raama/asutused"
                       render={(props) => <AsutusRegister history = {props.history} userData={this.props.userData} initData={this.props.initData} />}/>
                <Route exact path="/raama/sorder/:docId" component = {SorderDocument} />
                <Route exact path="/raama/sorder"
                       render={(props) => <SorderideRegister history = {props.history} userData={this.props.userData} initData={this.props.initData}/>}/>
                <Route exact path="/raama/vorder/:docId" component = {VorderDocument} />
                <Route exact path="/raama/vorder"
                       render={(props) => <VorderideRegister history = {props.history} userData={this.props.userData} initData={this.props.initData}/>}/>
                <Route exact path="/raama/smk/:docId" component = {SmkDocument} />
                <Route exact path="/raama/smk"
                       render={(props) => <SmkRegister history = {props.history} userData={this.props.userData} initData={this.props.initData}/>}/>
                <Route exact path="/raama/vmk/:docId" component = {VmkDocument} />
                <Route exact path="/raama/vmk"
                       render={(props) => <VmkRegister history = {props.history} userData={this.props.userData} initData={this.props.initData}/>}/>
                <Route exact path="/raama/journal/:docId" component = {JournalDocument} />
                <Route exact path="/raama/journal"
                       render={(props) => <JournalRegister history = {props.history} userData={this.props.userData} initData={this.props.initData} />}/>
                <Route exact path="/raama/kontod/:docId" component = {KontoDocument} />
                <Route exact path="/raama/kontod"
                       render={(props) => <KontoRegister history = {props.history} userData={this.props.userData} initData={this.props.initData} />}/>
                <Route exact path="/raama/nomenclature/:docId" component = {NomDocument} />
                <Route exact path="/raama/nomenclature"
                       render={(props) => <NomRegister history = {props.history} userData={this.props.userData} initData={this.props.initData} />}/>
                <Route exact path="/raama/project/:docId" component = {ProjectDocument} />
                <Route exact path="/raama/project"
                       render={(props) => <ProjectRegister history = {props.history} userData={this.props.userData} initData={this.props.initData} />}/>
                <Route exact path="/raama/tunnus/:docId" component = {TunnusDocument}/>
                <Route exact path="/raama/tunnus"
                       render={(props) => <TunnusRegister history = {props.history} userData={this.props.userData} initData={this.props.initData} />}/>
                <Route exact path="/raama/document/:docId" component = {DocumentLibDocument} />
                <Route exact path="/raama/document"
                       render={(props) => <DocumentLibRegister history = {props.history} userData={this.props.userData} initData={this.props.initData} />}/>
            </StyleRoot>)
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
        return components['TunnusDocument'] = (props) => {
            const TunnusDocument = require('./../docs/tunnus/document/index.jsx');
            return <TunnusDocument {...props}/>};
    }


}

module.exports = App;