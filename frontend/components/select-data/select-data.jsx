'use strict';

const PropTypes = require('prop-types');
const getDataByFilter = require('../../../libs/getDataByFilter');
const fetchData = require('./../../../libs/fetchData');

const React = require('react'),
    styles = require('./select-data-styles'),
    DataGrid = require('../../components/data-grid/data-grid.jsx'),
    Button = require('../../components/button-register/button-register.jsx'),
    InputText = require('../../components/input-text/input-text.jsx'),
    ModalPage = require('./../../components/modalpage/modalPage.jsx');

class SelectData extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            value: props.value, /* возвращаемое значение, например id*/
            fieldValue: props.defaultValue, /*видимое значение, например kood или name по указанному в collId */
            readOnly: props.readOnly,
            disabled: props.disabled,
            edited: props.edited,
            gridData: [],
            gridConfig: props.config,
            gridActiveRow: 0,
            show: this.props.show
        };
//        this.onChange = this.onChange.bind(this);
        this.handleInputChange = this.handleInputChange.bind(this);
        this.handleGridClick = this.handleGridClick.bind(this);
        this.modalPageClick = this.modalPageClick.bind(this);
        this.loadLibs = this.loadLibs.bind(this);
    }

    componentWillReceiveProps(nextProps) {

        this.setState({
            value: nextProps.value,
            fieldValue: nextProps.defaultValue,
            readOnly: nextProps.readOnly,
            show: nextProps.show,
        });
    }

    render() {
        let isEditeMode = !this.state.readOnly,
            btnStyle = Object.assign({}, styles.button, {display: isEditeMode ? 'inline' : 'none'});

        return (
            <div style={styles.wrapper}>
                <InputText ref="input"
                           title={this.props.title}
                           name={this.props.name}
                           value={this.state.fieldValue}
                           readOnly={!isEditeMode}
                           onChange={this.handleInputChange}/>
                <Button value='v'
                        ref="btnShow"
                        style={btnStyle}
                        onClick={(e) => this.handleClick(e)}>
                </Button>

                {
                    this.state.show ? this.modalPage() : null
                }
            </div>
        )
    }

    handleClick(e) {
        this.setState({
            show: true
        });
    }

    modalPage() {
        let modalObjects = ['btnOk', 'btnCancel'];

        return (
            <div>
                <ModalPage
                    modalObjects={modalObjects}
                    ref="modalpage-grid"
                    show={true}
                    modalPageBtnClick={this.modalPageClick}
                    modalPageName='Vali rea'>
                    <div ref="grid-row-container">
                        <InputText ref="input-filter"
                                   title='Otsingu parametrid'
                                   name='gridFilter'
                                   value={this.state.fieldValue}
                                   readOnly={false}
                                   onChange={this.handleInputChange}/>
                        <DataGrid gridData={this.state.gridData}
                                  gridColumns={this.state.gridConfig}
                                  onClick={this.handleGridClick}
                                  ref="data-grid"/>
                    </div>
                </ModalPage>
            </div>);
    }

    // обработчик события измения значения в текстовом (поисковом) поле
    handleInputChange(name, value) {
        this.setState({fieldValue: value, show: true});
        this.loadLibs();
    }

    modalPageClick(event) {
        if (event === 'Ok') {
            // надо найти активную строку

            let boundField = this.props.boundToGrid ? this.props.boundToGrid : 'name', //grid filed name
                boundToData = this.props.boundToData ? this.props.boundToData : false, //InputDefaultValue
                boundFieldData = this.props.name; //inputName = fieldname

            let activeRow = this.state.gridActiveRow,
                value = this.state.gridData[activeRow]['id'],
                fieldValue = this.state.gridData[activeRow][boundField];
            // получить данные полей и установить состояние для виджета

            // показать новое значение
            this.setState({value: value, fieldValue: fieldValue, show: false});

            // вернуть значение наверх

            if (this.props.onChange) {
                this.props.onChange(boundFieldData, value);

                // text value of input
                if (boundToData) {
                    this.props.onChange(boundToData, fieldValue);
                }

                //если привязано другое поле
                if (this.props.collName) {
                    this.props.onChange(this.props.collName, fieldValue);
                }
            }


        }
    }

    handleGridClick(event, value, activeRow) {
        this.setState({gridActiveRow: activeRow});
    }

    loadLibs() {
        const postUrl = '/newApi/loadLibs';
        let lib = this.props.libName;
        let sqlWhere = '';
        if (this.props.sqlFields.length && this.state.fieldValue) {
            this.props.sqlFields.forEach((field) => {
                let isOr = sqlWhere.length > 0 ? ' or ' : '';
                sqlWhere = sqlWhere.concat(` ${isOr} encode(${field}::bytea, 'escape') ilike '%${this.state.fieldValue.trim()}%'`);
            });
            sqlWhere = 'where ' + sqlWhere;
        }

        let libParams = sqlWhere.length ? {sql: sqlWhere} : {};

        fetchData.fetchDataPost(`${postUrl}/${lib}`, libParams).then(response => {
            if (response && 'data' in response) {
                let gridData = response.data.result.result.data;
                this.setState({gridData: gridData});
            }

        }).catch(error => {
            console.error('loadLibs error', error);
            rejected();
        });
    }


}

SelectData.propTypes = {
    readOnly: PropTypes.bool,
    disabled: PropTypes.bool,
    collId: PropTypes.string,
    title: PropTypes.string,
    placeholder: PropTypes.string,
    name: PropTypes.string.isRequired,
    show: PropTypes.bool
};

SelectData.defaultProps = {
    readOnly: false,
    disabled: false,
    btnDelete: false,
    value: 0,
    collId: 'id',
    title: '',
    show: false
};

module.exports = SelectData;
