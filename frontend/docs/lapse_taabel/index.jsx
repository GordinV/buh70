'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const InputNumber = require('../../components/input-number/input-number.jsx');
const getSum = require('./../../../libs/getSum');

const styles = require('./styles');
const DOC_TYPE_ID = 'LAPSE_TAABEL';

/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            summa: 0,
            soodustus: 0
        };
        this.renderer = this.renderer.bind(this);

    }

    render() {
        return (
            <div>

                <DocumentRegister history={this.props.history ? this.props.history : null}
                                  module={this.props.module}
                                  ref='register'
                                  docTypeId={DOC_TYPE_ID}
                                  style={styles}
                                  render={this.renderer}/>
                <InputNumber title="Summa kokku:"
                             name='summa_kokku'
                             style={styles.total}
                             ref="input-summa"
                             value={Number(this.state.summa).toFixed(2) || 0}
                             disabled={true}/>
                <InputNumber title="Soodustus kokku:"
                             name='soodustus_kokku'
                             style={styles.total}
                             ref="input-soodustus"
                             value={Number(this.state.soodustus).toFixed(2) || 0}
                             disabled={true}

                />
            </div>
        );

    }

    // custom render
    renderer(self) {
        let summa = self.gridData && self.gridData.length ? self.gridData[0].summa_kokku : 0;
        let soodustus = self.gridData  && self.gridData.length ? self.gridData[0].soodustus_kokku : 0;

        if (summa || soodustus) {
            this.setState({summa: summa, read: self.gridData.length, soodustus: soodustus});
        }

        return null;
    }

}


module.exports = (Documents);


