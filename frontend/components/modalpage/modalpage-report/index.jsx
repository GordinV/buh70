'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    ModalPage = require('../modalPage.jsx'),
    styles = require('./styles');

const GRID_CONFIG = require('./../../../../config/constants').tulemused.gridConfig;

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
                result: data.result ? 'Ok' : 'Viga',
                kas_vigane: Boolean(data.kas_vigane),
                error_code: data.error_code,
                error_message: data.error_message
            });
            if (!data.result) {
                errors++;
            }
        }

        if (data && data.data && typeof data == 'object' && data.data.length) {
            data.data.map((row) => {
                report.data.push({
                    id: row.id,
                    kas_vigane: Boolean(row.kas_vigane),
                    result: row.result ? 'Ok' : 'Viga',
                    error_code: row.error_code,
                    error_message: row.error_message
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
