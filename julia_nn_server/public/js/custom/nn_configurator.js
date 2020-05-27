var layer_count=0

function get_layer_selection_html(){
return `
<div class="layer_select_div" >
<label for="layer_${layer_count}"> Layer ${layer_count}: </label>
<select name="layer_${layer_count}" id="layer_${layer_count}" class="layer_select" required>
    <option value="linear">Linear</option>
    <option value="sigmoid">Sigmoid</option>
    <option value="relu">ReLU</option>
</select>
<br>
</div>
`
}

function get_layer_specific_options(layer_type){
    return {
        "linear": `
        <div class="layer_specific" style="display: inline">
        <label>Number of neurons: </label>
        <input type="number" name="neuron_count_${layer_count}" min="1" max="1000" value="1" required/>
        </div>
        `,
        "sigmoid": `
        <div class="layer_specific" style="display: inline"></div>`,
        "relu": `
        <div class="layer_specific" style="display: inline"></div>`
    }[layer_type]
}


function manage_remove_layer_button_visibility(){
    if (layer_count > 0){
        $('#remove_last_layer').css('visibility', 'visible')
    }
    else {
        $('#remove_last_layer').css('visibility', 'hidden')
    }
}
function add_new_layer() {
    layer_count = layer_count + 1
    $('#layers_fieldset').append(get_layer_selection_html())
    display_layer_specific($(`#layer_${layer_count}`))
    manage_remove_layer_button_visibility()
}
function remove_last_layer() {
    if (layer_count > 1) {
        layer_count = Math.max(layer_count -1, 0)
        $('.layer_select_div').last().remove()
        manage_remove_layer_button_visibility()
    }
}
function display_layer_specific(node) {
    var selected_value = $(node).find(":selected").val()
    var layer_specific = get_layer_specific_options(selected_value)
    $(node).after(layer_specific)
}

function remove_prev_layer_specific(node) {
    $(node).parent().find('.layer_specific').remove()
}


$(document).ready(function(){
    $('#add_new_layer').on('click', function() {
         add_new_layer();
    });
    $('#remove_last_layer').on('click', function() {
         remove_last_layer();
    });
    $('#layers_fieldset').on('change', '.layer_select', function() {
        remove_prev_layer_specific(this);
        display_layer_specific(this);
    });
    add_new_layer();
});
