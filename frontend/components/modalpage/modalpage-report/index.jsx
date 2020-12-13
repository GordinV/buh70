'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    ModalPage = require('../modalPage.jsx'),
    styles = require('./styles.js');


const TextArea = require('./../../text-area/text-area.jsx');
const DataGrid = require('../../data-grid/data-grid.jsx');


class ModalPageInfo extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            show: this.props.show
        }

    }

    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {
        if (nextProps.show !== prevState.show) {
            return {show: nextProps.show};
        } else return null;
    }


    render() {
        const GRID_CONFIG = require('./../../../../config/constants').tulemused.gridConfig;

        let systemMessage = this.props.systemMessage ? this.props.systemMessage : '',
            data = this.props.report ? this.props.report : '',
            modalObjects = ['btnOk'];

        let report = this.loeTulemused(data);

        return <ModalPage ref='modalPage'
                          style={styles.modalPage}
                          show={this.props.show}
                          modalPageBtnClick={this.props.modalPageBtnClick}
                          modalPageName='Tööülesanne report'
                          modalObjects={modalObjects}
        >
            <div ref="container">
                <img ref="image" src={styles.icon}/>
                <span> {systemMessage} </span>
                <div style={styles.docRow}>
                    <TextArea title="Report"
                              style={styles.tulemus}
                              name='report'
                              ref="textarea-report"
                              value={report.kokkuVotte}
                              readOnly={true}/>

                </div>
                <div ref="grid-row-container">
                    <DataGrid
                        gridData={report.data}
                        gridColumns={GRID_CONFIG}
                        showToolBar={false}
                        ref="data-grid"/>
                </div>


            </div>
        </ModalPage>
    }

    loeTulemused(data) {
        let report = {
            kokkuVotte: '',
            data: []
        };

        let errors = 0;
        // если один обьект
        if (data && data.data && typeof data.data == 'object' && !data.data.length) {
            report.data.push({
                id: 1,
                result: data.result && !data.error_code ? 'Ok' : 'Viga',
                kas_vigane: data.kas_vigane ? 'Viga' : 'Ok',
                error_code: data.error_code,
                error_message: data.error_message,
                viitenr: data.viitenr ? data.viitenr: null
            });
            if (!data.result) {
                errors++;
            }
        }

        if (data && data.data && typeof data == 'object' && data.data.length) {
            data.data.map((row, index) => {
                report.data.push({
                    id: row.id ? row.id: index ,
                    kas_vigane: row.kas_vigane ? 'Viga': 'Ok',
                    result: row.result && !row.error_code ? 'Ok' : 'Viga',
                    error_code: row.error_code,
                    error_message: row.error_message,
                    viitenr: row.viitenr ? row.viitenr: null
                });
                if (!row.result) {
                    errors++;
                }

            })
        }

        report.kokkuVotte = `Vead kokku ${errors}, Read kokku: ${report.data.length}, Õnnestus: ${report.data.length - errors}`;
        return report;
    }

}

ModalPageInfo.propTypes = {
    systemMessage: PropTypes.string,
    modalPageBtnClick: PropTypes.func
};

module.exports = ModalPageInfo;
