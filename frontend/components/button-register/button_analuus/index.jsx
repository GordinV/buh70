'use strict';

const React = require('react');
const PropTypes = require('prop-types');
const getNow = require('./../../../../libs/getNow');

const ModalPage = require('./../../modalpage/modalPage.jsx');

const styles = require('../button-register-styles'),
    Button = require('../button-register.jsx'),
    DataGrid = require('../../../components/data-grid/data-grid.jsx'),
    ToolbarContainer = require('./../../../components/toolbar-container/toolbar-container.jsx'),
    gridStyles = require('./styles');

const DOC_TYPE_ID = 'INF3_ANALUUS';
const config = require('./../../../../config/constants')[DOC_TYPE_ID].CONFIG;
const DocContext = require('./../../../doc-context.js');
const fetchData = require('./../../../../libs/fetchData');

const ICON = 'execute';


class ButtonTask extends React.PureComponent {
// кнопка создания документа в регистрах
    constructor(props) {
        super(props);
        this.state = {
            showModal: false,
            gridData: [],
            config: config,
            sqlWhere: props.sqlWhere,
            filterData: props.filterData,
            dataLoaded: false,
            warning: '', // строка извещений
            warningType: '',
        };
        this.handleClick = this.handleClick.bind(this);
        this.modalPageClick = this.modalPageClick.bind(this);
        this.handleInputChange = this.handleInputChange.bind(this);
        this.fetchData = this.fetchData.bind(this);
    }

    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {
        if (nextProps.sqlWhere !== prevState.sqlWhere) {
            return {sqlWhere: nextProps.sqlWhere};
        } else return null;
    }

    handleClick(e) {
        this.setState({showModal: true, gridData: []});
    }

    render() {
        if (this.state.showModal && !this.state.dataLoaded) {
            // загрузка данных
            this.fetchData()
        }

        let value = this.props.value ? this.props.value : 'Täitmine';
        let propStyle = ('style' in this.props) ? this.props.style : {};
        let style = Object.assign({}, gridStyles, propStyle);
        const warningStyle = this.state.warningType && gridStyles[this.state.warningType] ? gridStyles[this.state.warningType] : null;

        return (
            <div>
                <Button
                    show={true}
                    value={value}
                    ref={'btnTask' || this.props.ref}
                    style={style}
                    disabled={false}
                    onClick={this.handleClick}>
                    <img ref="image" src={styles.icons[ICON]}/>
                </Button>
                {this.state.showModal ?
                    <ModalPage
                        modalPageBtnClick={this.modalPageClick}
                        modalPageName={value}
                        show={true}
                        modalObjects={['btnOk']}
                    >
                        {this.state.warning ?
                            <ToolbarContainer ref='toolbar-container'>
                                <div style={warningStyle}>
                                    <span>{this.state.warning}</span>
                                </div>
                            </ToolbarContainer>
                            : null}


                        <DataGrid ref='dataGrid'
                                  style={style.grid.mainTable}
                                  gridData={this.state.gridData}
                                  gridColumns={this.state.config}
                            //                                  onHeaderClick={this.headerClickHandler}
                            //                                  custom_styling={this.props.custom_styling ? this.props.custom_styling : null}
                        />
                    </ModalPage> : null
                }
            </div>
        )
    }

    modalPageClick(btnEvent) {
        this.setState({showModal: false, dataLoaded: false});
        /*
                if (btnEvent === 'Ok') {
                    this.props.onClick(this.props.value, this.props.showKogus ? this.state.kogus : this.state.seisuga, this.state.kas_kond);
                }
        */
    }

    //will save value
    handleInputChange(name, value) {
        switch (name) {
            case 'kpv':
                this.setState({seisuga: value});
                break;
            case 'kogus':
                this.setState({kogus: value});
                break;
            case 'kas_kond':
                this.setState({kas_kond: value});
                break;

        }
    }

    fetchData() {
        this.setState({warning: 'Töötan...', warningType: 'notValid'});
        DocContext.paring_id++;

        let URL = `/newApi`;
        const params = {
            parameter: DOC_TYPE_ID, // параметры
            docTypeId: DOC_TYPE_ID, // для согласования с документом
            method: 'selectDocs',
            sqlWhere: this.props.sqlWhere, // динамический фильтр грида
            filterData: this.props.filterData,
            userId: DocContext.getUserId,
            uuid: DocContext.getUuid,
            module: 'Lapsed',
            limit: 1000,
            sortBy: [{column: 'kpv', direction: 'asc', type: 'date'}],
            paring_id: DocContext.paring_id
        };

        // неазначим paring_id

// ставим статус
//        this.setState({warning: 'Töötan...', warningType: 'notValid'});
        fetchData.fetchDataPost(URL, params)
            .then(response => {
                if (response.status && response.status == 401) {
                    console.error('Error 401, redirect');
                    document.location = `/login`;
                }
                if (response) {
                    if (response.data.paring_id === DocContext.paring_id) {

// наш запрос
                        let warning = 'Edukalt';
                        if (response.data && response.data.result && response.data.result.error_message) {
                            // нет ошибки, есть извещение. Покажем его в статусной строке
                            warning = response.data.result.error_message;
                        }

                        this.setState({
                            gridData: response.data.result.data,
                            dataLoaded: true,
                            warning: warning,
                            warningType: 'ok'
                        });
                    }/* else {
                        this.setState({warning: `Tekkis viga: vale päringu id`, warningType: 'error'});
                    }*/

                }
            })
            .catch(error => {
                this.setState({warning: `${error}`, warningType: 'error'});
                console.error('received error-> ', error);
                if (error) {
                    document.location = `/login`;
                }
            });

    }
}

ButtonTask.defaultProps = {
    disabled: false,
    show: true,
    showDate: true,
    showKogus: false,
    showKond: false
};

module.exports = ButtonTask;