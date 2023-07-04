function VS_plot(x, y, line_style, line_width, marker_style, marker_size, color, gap, textx, texty, textlegend, num_fig)
    figure(num_fig)
    set(gcf,'color','w');
    plot(x , y,'Color', color,'LineStyle', line_style, 'LineWidth', line_width, 'Marker', marker_style, 'MarkerSize', marker_size, 'MarkerIndices', 1:gap:length(y));
    xlabel(textx,'FontSize',13,'FontWeight','normal','Color','k')
    ylabel(texty,'FontSize',13,'FontWeight','normal','Color','k')
    grid on;
    %legend(textlegend)
    hold on;
end
