'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const InputNumber = require('../../components/input-number/input-number.jsx');
const getSum = require('./../../../libs/getSum');

const styles = require('./styles');

const DOC_TYPE_ID = 'AASTA_NAITAJAD';
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
            jaanuar: 0,
            veebruar: 0,
            marts: 0,
            apriil: 0,
            mai: 0,
            juuni: 0,
            juuli: 0,
            august: 0,
            september: 0,
            oktoober: 0,
            november: 0,
            detsember: 0,
            read: 0
        }

   }

    render() {
        return (
            <div>
                <DocumentRegister initData={this.props.initData}
                                  gridConfig = {this.props.gridConfig}
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
                <InputNumber title="Jaanuar kokku:"
                             name='jaanuar_kokku'
                             style={styles.total}
                             ref="input-jaanuar"
                             value={Number(this.state.jaanuar).toFixed(2) || 0}
                             disabled={true}/>
                <InputNumber title="Veebruar kokku:"
                             name='veebruar_kokku'
                             style={styles.total}
                             ref="input-veebruar"
                             value={Number(this.state.veebruar).toFixed(2) || 0}
                             disabled={true}/>
                <InputNumber title="Märts kokku:"
                             name='marts_kokku'
                             style={styles.total}
                             ref="input-marts"
                             value={Number(this.state.marts).toFixed(2) || 0}
                             disabled={true}/>
                <InputNumber title="Apriil kokku:"
                             name='apriil_kokku'
                             style={styles.total}
                             ref="input-apriil"
                             value={Number(this.state.apriil).toFixed(2) || 0}
                             disabled={true}/>
                <InputNumber title="Mai kokku:"
                             name='mai_kokku'
                             style={styles.total}
                             ref="input-mai"
                             value={Number(this.state.mai).toFixed(2) || 0}
                             disabled={true}/>
                <InputNumber title="Juuni kokku:"
                             name='juuni_kokku'
                             style={styles.total}
                             ref="input-juuni"
                             value={Number(this.state.juuni).toFixed(2) || 0}
                             disabled={true}/>
                <InputNumber title="Juuli kokku:"
                             name='juuli_kokku'
                             style={styles.total}
                             ref="input-juuli"
                             value={Number(this.state.juuli).toFixed(2) || 0}
                             disabled={true}/>
                <InputNumber title="August kokku:"
                             name='august_kokku'
                             style={styles.total}
                             ref="input-august"
                             value={Number(this.state.august).toFixed(2) || 0}
                             disabled={true}/>
                <InputNumber title="September kokku:"
                             name='september_kokku'
                             style={styles.total}
                             ref="input-september"
                             value={Number(this.state.september).toFixed(2) || 0}
                             disabled={true}/>
                <InputNumber title="Oktoober kokku:"
                             name='oktoober_kokku'
                             style={styles.total}
                             ref="input-oktoober"
                             value={Number(this.state.oktoober).toFixed(2) || 0}
                             disabled={true}/>
                <InputNumber title="November kokku:"
                             name='november_kokku'
                             style={styles.total}
                             ref="input-november"
                             value={Number(this.state.november).toFixed(2) || 0}
                             disabled={true}/>
                <InputNumber title="Detsember kokku:"
                             name='detsember_kokku'
                             style={styles.total}
                             ref="input-detsember"
                             value={Number(this.state.detsember).toFixed(2) || 0}
                             disabled={true}/>

            </div>
        )
    }

    renderer(self) {
        let jaanuar = self.gridData ? getSum (self.gridData,'jaanuar') : 0;
        let veebruar = self.gridData ? getSum (self.gridData,'veebruar') : 0;
        let marts = self.gridData ? getSum (self.gridData,'marts') : 0;
        let apriil = self.gridData ? getSum (self.gridData,'apriil') : 0;
        let mai = self.gridData ? getSum (self.gridData,'mai') : 0;
        let juuni = self.gridData ? getSum (self.gridData,'juuni') : 0;
        let juuli = self.gridData ? getSum (self.gridData,'juuli') : 0;
        let august = self.gridData ? getSum (self.gridData,'august') : 0;
        let september = self.gridData ? getSum (self.gridData,'september') : 0;
        let oktoober = self.gridData ? getSum (self.gridData,'oktoober') : 0;
        let november = self.gridData ? getSum (self.gridData,'november') : 0;
        let detsember = self.gridData ? getSum (self.gridData,'detsember') : 0;

        if (self.gridData) {
            this.setState({
                jaanuar: jaanuar,
                veebruar: veebruar,
                marts: marts,
                apriil: apriil,
                mai: mai,
                juuni:juuni,
                juuli: juuli,
                august: august,
                september: september,
                oktoober: oktoober,
                november: november,
                detsember: detsember,
                read: self.gridData.length});
        }

        return null;
    }



}


module.exports = (Documents);


