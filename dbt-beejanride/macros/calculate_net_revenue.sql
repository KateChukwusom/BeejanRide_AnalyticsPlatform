{% macro calculate_net_revenue(actual_fare_col, fee_col) %}

    -- Compute net revenue for a trip/payment
    {{ actual_fare_col }} - {{ fee_col }}

{% endmacro %}