'use strict';
const React = require('react');
const PropTypes = require('prop-types');

const DocumentTemplate = require('./../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    Loading = require('./../../../components/loading/index.jsx'),
    SelectData = require('../../../components/select-data/select-data.jsx');

const DocContext = require('../../../doc-context');

const styles = require('./styles');

const LIBRARIES = [
    {id: 'laps', filter: ''},
];


/**
 * Класс реализует документ справочника признаков.
 */
class Viitenr extends React.PureComponent {
    constructor(props) {
        super(props);

        this.state = {
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            loadedData: false,
            lapsId: null
        };
        this.renderer = this.renderer.bind(this);
    }

    componentDidMount() {
        let lapsId;

        //если параметр на ребенка задан в стейте, то используем его. Иначе ищем его в контексте
        if (this.props.history && this.props.history.location.state) {
            lapsId = this.props.history.location.state.lapsId;
        } else {
            lapsId = DocContext['laps'] ? DocContext['laps'] : null;
        }
        this.setState({lapsId: lapsId});

    }


    render() {
        return (
            <DocumentTemplate docId={this.state.docId}
                              ref='document'
                              docTypeId='VIITENR'
                              module={this.props.module}
                              initData={this.props.initData}
                              userData={this.props.userData}
                              libs={LIBRARIES}
                              reload={true}
                              renderer={this.renderer}
                              focusElement={'input-viitenumber'}
                              history={this.props.history}

            />
        )
    }

    /**
     * Метод вернет кастомный компонент
     * @param self
     * @returns {*}
     */
    renderer(self) {
        if (!self.docData) {
            // не загружены данные
            return (<div style={styles.doc}>
                <Loading label={'Laadimine...'}/>
            </div>);
        }

        if ((!Number(self.docData.id) || !self.docData.laps_id) && this.state.lapsId) {
            //new record
            self.docData.laps_id = this.state.lapsId;
            let lapsRow = self.libs['laps'].filter(laps => laps.id == this.state.lapsId);
            if (lapsRow) {
                self.docData.nimi = lapsRow.nimi;
                self.docData.isikukood = lapsRow.isikukood;
            }
        }

        return (
            <div style={styles.doc}>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputText title="Asutus"
                                   name='asutus'
                                   ref="input-asutus"
                                   readOnly={true}
                                   value={self.docData.asutus || ''}
                                   onChange={self.handleInputChange}/>
                    </div>
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputText title="Viitenumber "
                                   name='viitenumber'
                                   ref="input-viitenumber"
                                   readOnly={!self.state.edited}
                                   value={self.docData.viitenumber || ''}
                                   onChange={self.handleInputChange}/>
                    </div>
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <SelectData title="Lapse nimi:"
                                    name='laps_id'
                                    userData={self.userData}
                                    libName="laps"
                                    sqlFields={['nimi', 'isikukood']}
                                    data={[]}
                                    value={self.docData.laps_id || 0}
                                    defaultValue={self.docData.nimi}
                                    boundToGrid='nimi'
                                    boundToData='nimi'
                                    ref="select-isikukood"
                                    btnDelete={false}
                                    onChange={self.handleInputChange}
                                    history={this.props.history}
                                    readOnly={!self.state.edited}/>
                    </div>
                </div>
            </div>
        );
    }

}

Viitenr.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object
};

Viitenr.defaultProps = {
    initData: {},
};


module.exports = (Viitenr);
