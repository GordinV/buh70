'use strict';

const React = require('react');

const Menu = require('./../components/menu-toolbar/menu-toolbar.jsx');

const Docs = require('./../docs/dok/index.jsx');

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

    }

    render() {
        const context = {};
        let btnParams = this.prepareParamsForToolbar();

        return (
            <StyleRoot>
                <Route  path="/lapsed"
                        render={() => <Menu params = {btnParams} userData={this.state.userData} module={MODULE}/>}/>
                <Route exact path="/lapsed"
                       render={(props) => <Docs history = {props.history} userData={this.props.userData} initData={this.props.initData}/>}/>
                <Route exact path="/lapsed/docs"
                       render={(props) => <Docs history = {props.history} userData={this.props.userData} initData={this.props.initData}/>}/>
                <Route exact path="/lapsed/laps"
                       render={(props) => <Docs history = {props.history} userData={this.props.userData} initData={this.props.initData}/>}/>
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

}

module.exports = App;