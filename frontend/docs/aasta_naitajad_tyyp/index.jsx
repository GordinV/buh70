'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const InputNumber = require('../../components/input-number/input-number.jsx');
const InputText = require('../../components/input-text/input-text.jsx');
const getSum = require('./../../../libs/getSum');

const styles = require('./styles');

const DOC_TYPE_ID = 'AASTA_NAITAJAD_TYYP';
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
            jaanuar: '',
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
            read: 0,
            ristKasutus: 0

        }

    }

    render() {
        let ristKasutuswarning = this.state.ristKasutus ? `See aruanne sisaldab ${this.state.ristKasutus} isik/isikut, kes saavad korraga teenuseid erinevates üksustes` : null;

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
                <label>
                    {ristKasutuswarning}
                </label>

                <InputNumber title="Read kokku:"
                             name='read_kokku'
                             style={styles.total}
                             ref="input-read"
                             value={Number(this.state.read) || 0}
                             disabled={true}/>
                <InputText title="Jaanuar kokku:"
                           name='jaanuar_kokku'
                           style={styles.total}
                           ref="input-jaanuar"
                           value={this.state.jaanuar || 0}
                           disabled={true}/>
                <InputText title="Veebruar kokku:"
                           name='veebruar_kokku'
                           style={styles.total}
                           ref="input-veebruar"
                           value={this.state.veebruar || 0}
                           disabled={true}/>
                <InputText title="Märts kokku:"
                           name='marts_kokku'
                           style={styles.total}
                           ref="input-marts"
                           value={this.state.marts || 0}
                           disabled={true}/>
                <InputText title="Apriil kokku:"
                           name='apriil_kokku'
                           style={styles.total}
                           ref="input-apriil"
                           value={this.state.apriil || 0}
                           disabled={true}/>
                <InputText title="Mai kokku:"
                           name='mai_kokku'
                           style={styles.total}
                           ref="input-mai"
                           value={this.state.mai || 0}
                           disabled={true}/>
                <InputText title="Juuni kokku:"
                           name='juuni_kokku'
                           style={styles.total}
                           ref="input-juuni"
                           value={this.state.juuni || 0}
                           disabled={true}/>
                <InputText title="Juuli kokku:"
                           name='juuli_kokku'
                           style={styles.total}
                           ref="input-juuli"
                           value={this.state.juuli || 0}
                           disabled={true}/>
                <InputText title="August kokku:"
                           name='august_kokku'
                           style={styles.total}
                           ref="input-august"
                           value={this.state.august || 0}
                           disabled={true}/>
                <InputText title="September kokku:"
                           name='september_kokku'
                           style={styles.total}
                           ref="input-september"
                           value={this.state.september || 0}
                           disabled={true}/>
                <InputText title="Oktoober kokku:"
                           name='oktoober_kokku'
                           style={styles.total}
                           ref="input-oktoober"
                           value={this.state.oktoober || 0}
                           disabled={true}/>
                <InputText title="November kokku:"
                           name='november_kokku'
                           style={styles.total}
                           ref="input-november"
                           value={this.state.november || 0}
                           disabled={true}/>
                <InputText title="Detsember kokku:"
                           name='detsember_kokku'
                           style={styles.total}
                           ref="input-detsember"
                           value={this.state.detsember || 0}
                           disabled={true}/>

            </div>
        )
    }

    renderer(self) {
        let jaanuar = 0;
        let veebruar = 0;
        let marts = 0;
        let apriil = 0;
        let mai = 0;
        let juuni = 0;
        let juuli = 0;
        let august = 0;
        let september = 0;
        let oktoober = 0;
        let november = 0;
        let detsember = 0;

        let jaanuar_pohi = 0;
        let veebruar_pohi = 0;
        let marts_pohi = 0;
        let apriil_pohi = 0;
        let mai_pohi = 0;
        let juuni_pohi = 0;
        let juuli_pohi = 0;
        let august_pohi = 0;
        let september_pohi = 0;
        let oktoober_pohi = 0;
        let november_pohi = 0;
        let detsember_pohi = 0;

        let jaanuar_vaba = 0;
        let veebruar_vaba = 0;
        let marts_vaba = 0;
        let apriil_vaba = 0;
        let mai_vaba = 0;
        let juuni_vaba = 0;
        let juuli_vaba = 0;
        let august_vaba = 0;
        let september_vaba = 0;
        let oktoober_vaba = 0;
        let november_vaba = 0;
        let detsember_vaba = 0;

        if (self.gridData && self.gridData.length) {
            let data = self.gridData[0];
            var ristKasutus = 0;

            self.gridData.forEach(row => {
                jaanuar += row.jaanuar;
                veebruar += row.veebruar;
                marts += row.marts;
                apriil += row.apriil;
                mai += row.mai;
                juuni += row.juuni;
                juuli += row.juuli;
                august += row.august;
                september += row.september;
                oktoober += row.oktoober;
                november += row.november;
                detsember += row.detsember;

                if (row.liik === 'Põhiõpe') {
                    jaanuar_pohi += row.jaanuar;
                    veebruar_pohi += row.veebruar;
                    marts_pohi += row.marts;
                    apriil_pohi += row.apriil;
                    mai_pohi += row.mai;
                    juuni_pohi += row.juuni;
                    juuli_pohi += row.juuli;
                    august_pohi += row.august;
                    september_pohi += row.september;
                    oktoober_pohi += row.oktoober;
                    november_pohi += row.november;
                    detsember_pohi += row.detsember;
                }

                if (row.liik === 'Vabaõpe') {
                    jaanuar_vaba += row.jaanuar;
                    veebruar_vaba += row.veebruar;
                    marts_vaba += row.marts;
                    apriil_vaba += row.apriil;
                    mai_vaba += row.mai;
                    juuni_vaba += row.juuni;
                    juuli_vaba += row.juuli;
                    juuli_vaba += row.august;
                    september_vaba += row.september;
                    oktoober_vaba += row.oktoober;
                    november_vaba += row.november;
                    detsember_vaba += row.detsember;

                }

            });

            this.setState({
                jaanuar: `${jaanuar} (s.h. Põhiõpe:${jaanuar_pohi} Vabaõpe:${jaanuar_vaba})`,
                veebruar: `${veebruar} (s.h. Põhiõpe:${veebruar_pohi} Vabaõpe:${veebruar_vaba})`,
                marts: `${marts} (s.h. Põhiõpe:${marts_pohi} Vabaõpe:${marts_vaba})`,
                apriil: `${apriil} (s.h. Põhiõpe:${apriil_pohi} Vabaõpe:${apriil_vaba})`,
                mai: `${mai} (s.h. Põhiõpe:${mai_pohi} Vabaõpe:${mai_vaba})`,
                juuni: `${juuni} (s.h. Põhiõpe:${juuni_pohi} Vabaõpe:${juuni_vaba})`,
                juuli: `${juuli} (s.h. Põhiõpe:${juuli_pohi} Vabaõpe:${juuli_vaba})`,
                august: `${august} (s.h. Põhiõpe:${august_pohi} Vabaõpe:${juuli_vaba})`,
                september: `${september} (s.h. Põhiõpe:${september_pohi} Vabaõpe:${september_vaba})`,
                oktoober: `${oktoober} (s.h. Põhiõpe:${oktoober_pohi} Vabaõpe:${oktoober_vaba})`,
                november: `${november} (s.h. Põhiõpe:${november_pohi} Vabaõpe:${november_vaba})`,
                detsember: `${detsember} (s.h. Põhiõpe:${detsember_pohi} Vabaõpe:${detsember_vaba})`,
                read: self.gridData.length,
                ristKasutus: self.gridData[0].rist_kasutus
            });
        }

        return null;
    }

}

module.exports = (Documents);


