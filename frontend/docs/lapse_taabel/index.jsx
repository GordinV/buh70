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
            summa: 0
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
                                  docTypeId={DOC_TYPE_ID}
                                  style={styles}
                                  render={this.renderer}/>
                <InputNumber title="Summa kokku:"
                             name='summa_kokku'
                             style={styles.total}
                             ref="input-summa"
                             value={Number(this.state.summa).toFixed(2) || 0}
                             disabled={true}

                />
            </div>
        );

    }

    // custom render
    renderer(self) {
        let summa = getSum(self.gridData || [],'summa');
        if (summa) {
            this.setState({summa: summa});
        }
        return <div>Lapse taabel register special render</div>
    }

}


module.exports = (Documents);


