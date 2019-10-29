'use strict';

const PropTypes = require('prop-types');
const radium = require('radium');

const React = require('react'),
    styles = require('./select-styles');

class Index extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            value: props.value ? props.value: 0 /* здесь по значению ИД */,
            readOnly: props.readOnly,
            disabled: props.disabled,
            fieldValue: props.defaultValue ? props.defaultValue: '' /*здесь по значени поля collId */,
            btnDelete: props.btnDelete /* если истину, то рисуем рядом кнопку для очистки значения*/
        };

        this.onChange = this.onChange.bind(this);

    }

    /**
     * привяжет к значеню поля
     * @param data - коллекция
     * @param collId - поле
     * @param value - значение
     */
    findFieldValue(data, collId, value) {
        // надо привязать данные
        data.forEach((row) => {
            if (row[collId] == value) {
                this.setState({value: row[collId], fieldValue: row[collId]});
            }
        }, this);
    }

    /**
     *
     * @param collId
     * @param rowId
     * @returns {*}
     */
    getValueById(collId, rowId) {
        // вернет значения поля по выбранному ИД

        let fieldValue,
            data = this.props.data;

        data.forEach((row) => {
            if (row[collId] == rowId) {
                fieldValue = row[collId];
                this.setState({fieldValue: fieldValue});
            }
        }, this);

        return fieldValue;
    }

    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {

        if (nextProps.value !== prevState.value ) {
            return {value: nextProps.value};
        } else return null;

    }


    componentDidMount() {
        if (this.props.collId && this.props.collId !== 'id') {
            // ищем ИД по значению поля
            this.findFieldValue(this.props.data, this.props.collId, this.props.value);
        }
    }

    onChange(e) {
        let fieldValue = e.target.value;

        if (fieldValue == '') {
            fieldValue = null;
        }

        if (this.props.collId) {
            // найдем по ид значение поля в collId
            fieldValue = this.getValueById(this.props.collId, fieldValue);
        }
        // сохраним ид как value
        this.setState({value: e.target.value, fieldValue: fieldValue});

        if (this.props.onChange) {
            // смотрим к чему привязан селект и отдаим его наверх
            this.props.onChange(this.props.name, fieldValue); // в случае если задан обработчик на верхнем уровне, отдадим обработку туда
        }
    }

    render() {
        let inputReadOnly = this.state.readOnly || false,
            inputDefaultValue = this.props.defaultValue ? this.props.defaultValue : this.props.value || ''; // Дадим дефолтное значение для виджета, чтоб покать его сразу, до подгрузки библиотеки

        if (!this.state.value) {
            // добавим пустую строку в массив

            // проверим наличие пустой строки в массиве
            let emptyObj = this.props.data.filter((obj) => {
                if (obj.id === 0) {
                    return obj;
                }
            });

        }

        let selectStyle = Object.assign({}, styles.select, inputReadOnly ? styles.hide : {}, inputReadOnly ? styles.readOnly : {});

        return (
            <select ref="select"
                    style={selectStyle}
                    value={this.state.value || 0}
                    id={this.props.name}
                    onChange={this.onChange}>
                {this.prepaireDataOptions()}
            </select>);
    }


    /**
     * Подготовит датасет для селекта
     * @returns {*}
     */
    prepaireDataOptions() {
        let options;
        let data = this.props.data.length ? this.props.data : [];

//        data.unshift({id:0, kood:'', name:''});
        if (data.length) {

            options = data.map((item, index) => {
                let key = 'option-' + index;
                let separator = ' ';
                let rowValue = `${item.kood ? item.kood : ''} ${separator} ${item.name}`;
                return (<option
                    value={this.props.data.length ? item[this.props.collId] : 0}
                    key={key}
                    ref={key}> {rowValue}
                </option>)
            }, this);
        } else {
            options = <option value={0} key={Math.random()}></option>;
        }
        return options;
    }

    /**
     * установит фокус на элементы
     */
    focus() {
        this.refs['select'].focus();
    }

}

Index.propTypes = {
    data: PropTypes.arrayOf(PropTypes.shape({
        id: PropTypes.number,
        kood: PropTypes.string,
        nimetus: PropTypes.string
    })),
    readOnly: PropTypes.bool,
    disabled: PropTypes.bool,
    btnDelete: PropTypes.bool,
    libs: PropTypes.string,
    collId: PropTypes.string.isRequired,
    title: PropTypes.string,
    placeholder: PropTypes.string,
    defaultValue: PropTypes.string
};

Index.defaultProps = {
    readOnly: false,
    disabled: false,
    valid: true,
    btnDelete: false,
    collId: 'id',
    title: '',
    defaultValue: '',
    data: [{id: 0, kood: '', nimetus: ''}]
};

module.exports = radium(Index);
