'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    styles = require('./tree-styles.js');

class Tree extends React.PureComponent {
    constructor(props) {
        super(props);

        this.state = {
            index: this.getIndex(props.value),
            value: props.value,
            hover: false
        };
        this.handleLiClick = this.handleLiClick.bind(this);
        this.toggleHover = this.toggleHover.bind(this);
    }

    componentDidUpdate(nextProps) {
        this.getIndex(nextProps.value);
        this.setState({index: this.getIndex(nextProps.value), value: nextProps.value});
    }

    render() {
        return (
            <div ref="tree">
                {this.getTree('0')}
            </div>
        );
    }

    /**
     * Обработчик для клика
     * @param selectedIndex
     * @param selectedId
     * @param isNode
     */
    handleLiClick(selectedIndex, selectedId, isNode) {
        if (!isNode && !isNaN(selectedId)) {
            // не нода, а документ
            let data = this.props.data.filter((row) => {
                    if (row.id === selectedId) {
                        return row;
                    }
                }),
                value = data[0][this.props.bindDataField];

            this.setState({
                index: selectedIndex,
                value: value
            });

            if (this.props.onClickAction) {
                this.props.onClickAction(this.props.name + 'Change', value);
            }
        }
    }

    /**
     * вернет данные для ноды = parentId
     * @param parentId
     */
    getChildren(parentId) {
        return this.props.data.filter((row) => {
            if (row.parentid == parentId) {
                return row;
            }
        });
    }

    /**
     * Построет дерево для ноды = parentId
     * @param parentId
     * @returns {XML}
     */
    getTree(parentId) {
        let data = this.getChildren(parentId),
            value = this.state.value;

        let linkStyle;
        if (this.state.hover) {
            linkStyle = {backgroundColor: 'red'}
        } else {
            linkStyle = {backgroundColor: 'blue'}
        }

        return (<ul style={styles.ul} ref='tree-ul'>
            {data.map((subRow, index) => {
                let style = Object.assign({}, styles.li,
                    value === subRow[this.props.bindDataField] && !subRow.is_node ? styles.focused : {}),
                    refId = 'li-' + index + Math.random();

                return (
                    <li
                        style={style}
                        onClick={this.handleLiClick.bind(this, index, subRow.id, subRow.is_node)}
                        key={refId}
                        ref={refId}>
                        {subRow.name} {this.getTree(subRow.id)}
                    </li>)
            })
            }

        </ul>)
    }


    toggleHover() {
        this.setState({hover: !this.state.hover})
    }

    /**
     * Вернет индекс строки где заданное поле имеет значение value
     * @param value
     * @returns {number}
     */
    getIndex(value) {
        let treeIndex = 0;
        // we got value, we should find index and initilize idx field
        for (let i = 0; i++; i < this.props.data[0].length) {
            if (this.props.data[0].data[i][this.props.bindDataField] === value) {
                // found
                return i;
            }
        }
        return treeIndex;
    }

}

Tree.propTypes = {
    value: PropTypes.string,
    data: PropTypes.array,
    bindDataField: PropTypes.string.isRequired
};

Tree.defaultProps = {
    data: [{
        id: 0,
        parentId: 0,
        name: '',
        kood: '',
        selected: false
    }],
    value: null,
    bindDataField: 'id'
};

module.exports = Tree;
