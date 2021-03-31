'use strict';

const PropTypes = require('prop-types');
const radium = require('radium');

const React = require('react'),
    styles = require('./select-styles');

class Select extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            data: props.data,
            value: 0/* здесь по значению ИД */,
            readOnly: props.readOnly,
            disabled: props.disabled,
            fieldValue: props.value /*здесь по значени поля collId */,
            btnDelete: props.btnDelete /* если истину, то рисуем рядом кнопку для очистки значения*/
        };

        this.onChange = this.onChange.bind(this);
        this.btnDelClick = this.btnDelClick.bind(this);
        this.getValueById = this.getValueById.bind(this);

    }

    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {
        if (nextProps.value !== prevState.value || nextProps.readOnly !== prevState.readOnly || JSON.stringify(nextProps.data) !== JSON.stringify(prevState.data)) {
            return {value: nextProps.value, readOnly: nextProps.readOnly, data:nextProps.data};
        } else return null;
    }

    componentDidMount() {
        if (this.props.collId && this.props.collId !== 'id') {
            // ищем ИД по значению поля
            this.getValueById(this.state.data, this.props.collId, this.state.value);
        }

    }

    onChange(e) {
        let fieldValue = e.target.value;

        if (fieldValue === '') {
            fieldValue = null;
        }

        if (this.props.collId && this.props.collId !== 'id') {
            // найдем по ид значение поля в collId
            fieldValue = this.getValueById(this.state.data, this.props.collId, fieldValue);
        }
        // сохраним ид как value
        this.setState({fieldValue: fieldValue, value: e.target.value});

        if (this.props.onChange) {
            // смотрим к чему привязан селект и отдаим его наверх
            this.props.onChange(this.props.name, fieldValue); // в случае если задан обработчик на верхнем уровне, отдадим обработку туда
        }
    }

    render() {
        const selectStyle = Object.assign({}, styles.select,
            this.props.style ? this.props.style : {});

        return (
            <div style={styles.wrapper} ref="wrapper">
                {this.props.title ?
                    <label ref="label" style={styles.label}
                           htmlFor={this.props.name}>{this.props.title}
                    </label>
                    : null}

                <select ref="select"
                        style={selectStyle}
                        value={this.state.value || 0}
                        id={this.props.name}
                        disabled={this.state.readOnly}
                        size={this.props.size ? this.props.size : 0}
                        onChange={this.onChange}>
                    {this.prepaireDataOptions()}
                </select>
            </div>)
    }


    /**
     *
     * @param collId
     * @param rowId
     * @returns {*}
     */
    getValueById(data, collId, rowId) {
        // вернет значения поля по выбранному ИД
        let fieldValue = 0;
        const foundRow = data.find(row => row[collId] === rowId);
        if (foundRow) {
            fieldValue = foundRow[collId];
        }

        return fieldValue;
    }


        btnDelClick(event) {
        // по вызову кнопку удалить, обнуляет значение
        this.setState({value: ''});
        this.onChange(event);
    }


    /**
     * Подготовит датасет для селекта
     * @returns {*}
     */
    prepaireDataOptions() {
        let options;
        let data = this.state.data.length ? this.state.data : [];

        if (data.length) {
            if (!this.state.value && !data.find(row => row.id === 0)) {
                // will add empty row
                data.unshift({id: 0, kood: '', nimetus: ''});
            }

            options = data.map((item, index) => {
                let key = 'option-' + index;
                let separator = ' ';
                let rowValue = `${item.kood ? item.kood : ''} ${separator} ${item.name ? item.name : item.nimetus}`;
                return <option value={item[this.props.collId]} key={key}
                               ref={key}> {rowValue} </option>
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

Select.propTypes = {
    data: PropTypes.arrayOf(PropTypes.shape({
        id: PropTypes.number,
        kood: PropTypes.string,
        nimetus: PropTypes.string
    })),
    readOnly: PropTypes.bool,
    disabled: PropTypes.bool,
    btnDelete: PropTypes.bool,
    collId: PropTypes.string.isRequired,
    title: PropTypes.string,
    placeholder: PropTypes.string,
    defaultValue: PropTypes.string
};

Select.defaultProps = {
    readOnly: false,
    disabled: false,
    valid: true,
    btnDelete: false,
    collId: 'id',
    title: '',
    defaultValue: '',
    data: [{id: 0, kood: '', nimetus: ''}]
};

module.exports = radium(Select);

