'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const InputNumber = require('../../components/input-number/input-number.jsx');
const getSum = require('./../../../libs/getSum');

const styles = require('./styles');
const DOC_TYPE_ID = 'LAPS_KOKKUVOTTE';
const TOOLBAR_PROPS = {
    add: false,
    edit: false,
    delete: false,
    start: false,
    print: true,
    email: true
};

/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            summa: 0,
            tasutud: 0,
            jaak: 0,
            read: 0
        };

        this.renderer = this.renderer.bind(this);
    }

    render() {
        return (
            <div>
                <DocumentRegister initData={this.props.initData}
                                  history={this.props.history ? this.props.history : null}
                                  module={this.props.module}
                                  ref='register'
                                  toolbarProps={TOOLBAR_PROPS}
                                  docTypeId={DOC_TYPE_ID}
                                  style={styles}
                                  render={this.renderer}/>
                <InputNumber title="Read kokku:"
                             name='read_kokku'
                             style={styles.total}
                             ref="input-read"
                             value={Number(this.state.read) || 0}
                             disabled={true}/>
                <InputNumber title="Arve summa kokku:"
                             name='summa_kokku'
                             style={styles.total}
                             ref="input-summa"
                             value={Number(this.state.summa).toFixed(2) || 0}
                             disabled={true}/>
                <InputNumber title="Jääk kokku:"
                             name='jaak_kokku'
                             style={styles.total}
                             ref="input-jaak"
                             value={Number(this.state.jaak).toFixed(2) || 0}
                             disabled={true}/>
                <InputNumber title="Tasutud kokku:"
                             name='tasutud_kokku'
                             style={styles.total}
                             ref="input-tasutud"
                             value={Number(this.state.tasutud).toFixed(2) || 0}
                             disabled={true}/>
            </div>
        )
    }

    renderer(self) {
        let summa = self.gridData ? getSum (self.gridData,'summa') : 0;
        let tasutud = self.gridData ? getSum (self.gridData,'tasutud') : 0;
        let jaak = self.gridData ? getSum (self.gridData,'jaak') : 0;
        if (summa) {
            this.setState({summa: summa, tasutud: tasutud, jaak: jaak, read: self.gridData.length});
        }

        return (<div/>
        )
    }

}


module.exports = (Documents);


