# Arma Orienteering
 A simple mission for Arma 3 to practice orienteering and land-nav.

 If you wish to use this with a map not [already configured here](https://steamcommunity.com/id/landr1c/myworkshopfiles/?appid=107410 "Landric's Steam Workshop"), just add these files to your mission folder (e.g. `Orienteering.MyMap`).

 Custom courses can be predefined using markers in the editor in the following format: `course1` to designate the start location, and then `course1_1`, `course1_2`, `course1_3`, etc. to designate each of the checkpoints. Make sure to set the alpha of the markers to 0%.

Then update the following code-block in `description.ext` in order to allow players to chose from your custom courses:

    class Course
    {
        title = "Course (if not 'Random', this will overwrite some of the above settings)";
        texts[] = {
            "Random",
            "Course #1 (Easy, Short, 6 checkpoints, Rural navigation)",
            "Course #2 (Easy, Short, 8 checkpoints, Urban navigation)",
            "Course #3 (Hard, Far, 5 checkpoints, Wetlands navigation)",
            "Course #4 (Hard, Far, 7 checkpoints, Mountain navigation)"
        };
        values[] = {0,1,2,3,4};
        default = 0;
    };