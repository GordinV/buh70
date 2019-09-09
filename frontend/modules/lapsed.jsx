'use strict';

const React = require('react');

const Menu = require('./../components/menu-toolbar/menu-toolbar.jsx');

const Docs = require('./../docs/dok/index.jsx');
const LapseDokument = require('./../docs/laps/document/index.jsx');

const LasteRegister = require('./../docs/laps/index.jsx');

const ArvedeRegister = require('./../docs/arv/index.jsx');

const SmkRegister = require('./../docs/smk/index.jsx');

const SorderideRegister = require('./../docs/sorder/index.jsx');

const {Route, withRouter} = require('react-router-dom');
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
                <Route  path="/lapsed"
                        render={() => <Menu params = {btnParams} userData={this.state.userData} module={MODULE}/>}/>
                <Route exact path="/lapsed"
                       render={(props) => <Docs history = {props.history} userData={this.props.userData} initData={this.props.initData}  module={MODULE}/>}/>
                <Route exact path="/lapsed/docs"
                       render={(props) => <Docs history = {props.history} userData={this.props.userData} initData={this.props.initData}  module={MODULE}/>}/>
                <Route exact path="/lapsed/laps"
                       render={(props) => <LasteRegister history = {props.history} userData={this.props.userData} initData={this.props.initData} module={MODULE}/>}/>
                <Route exact path="/lapsed/laps/:docId" component = {LapseDokument} />
                <Route exact path="/lapsed/arv"
                       render={(props) => <ArvedeRegister history = {props.history} userData={this.props.userData} initData={this.props.initData} module={MODULE}/>}/>
                <Route exact path="/raama/smk"
                       render={(props) => <SmkRegister history = {props.history} userData={this.props.userData} initData={this.props.initData} module={MODULE}/>}/>
                <Route exact path="/raama/sorder"
                       render={(props) => <SorderideRegister history = {props.history} userData={this.props.userData} initData={this.props.initData} module={MODULE}/>}/>

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
        return components['LapseDocument'] = (props) => {
            const LapseDocument = require('./../docs/laps/document/index.jsx');
            return <LapseDocument {...props}/>};
    }


}

module.exports = App;