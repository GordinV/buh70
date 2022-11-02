'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const InputNumber = require('../../components/input-number/input-number.jsx');
const getSum = require('./../../../libs/getSum');

const styles = require('./styles');

const DOC_TYPE_ID = 'SELGEMATA_MAKSED';
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
        this.renderer = this.renderer.bind(this);

        this.state = {
            read: 0,
            summa: 0
        }

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

                <InputNumber title="Summa kokku:"
                             name='summa_kokku'
                             style={styles.total}
                             ref="input-sum,ma"
                             value={Number(this.state.summa) || 0}
                             disabled={true}/>
            </div>
        )
    }

    renderer(self) {
        let summa = self.gridData ? getSum(self.gridData, 'summa') : 0;

        if (self.gridData) {
            this.setState({
                summa: summa, read: self.gridData.length
            });
        }

        return null;
    }


}


module.exports = (Documents);


