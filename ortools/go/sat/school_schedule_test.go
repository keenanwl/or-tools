package sat

/*func Test_SchoolSchedule(t *testing.T) {

	subjects := []string{"English", "Math", "History"}
	levels := []string{"1-", "2-", "3-"}
	sections := []string{"A"}
	teachers := []string{"Mario", "Pete", "Casper", "Elvis"}
	teacherWorkHours := []int{18, 12, 12, 18}
	workingDays := []string{"Monday", "Tuesday", "Wednesday", "Thursday", "Friday"}
	periods := []string{"8:00-9:30", "9:45-11:15", "11:30-13:00"}
	curriculum := []Curriculum{
		{Hours: 3, Level: "1-", Subject: "English"},
		{Hours: 3, Level: "1-", Subject: "Math"},
		{Hours: 2, Level: "1-", Subject: "History"},
		{Hours: 4, Level: "2-", Subject: "English"},
		{Hours: 2, Level: "2-", Subject: "Math"},
		{Hours: 2, Level: "2-", Subject: "History"},
		{Hours: 2, Level: "3-", Subject: "English"},
		{Hours: 4, Level: "3-", Subject: "Math"},
		{Hours: 2, Level: "3-", Subject: "History"},
	}
	specialtyIndex := [][]int{
		{1, 3},
		{0, 3},
		{2, 3},
	}

	model := NewCpModel()

	for c := 0; c < len(levels)*len(subjects); c++ {
		for s, sVal := range subjects {
			for t, tVal := range teachers {
				for _, slotVal := range slots(workingDays, periods) {

					if in(specialtyIndex[s], t) {
						model.NewIntVar(
							0,
							1,
							fmt.Sprintf("%v %v %v %v", c, sVal, tVal, slotVal))
					} else {
						model.NewIntVar(
							0,
							0,
							fmt.Sprintf("NO DISP: %v %v %v %v", c, sVal, tVal, slotVal))
					}

				}
			}
		}
	}

	for level := range levels {
		for section := range sections {
			course := level*len(sections) + section
		}
	}

}

func in(source []int, val int) bool {

	for _, sourceVal := range source {
		if sourceVal == val {
			return true
		}
	}

	return false

}

func slots(workingDays []string, periods []string) []string {

	out := make([]string, 0)

	for day := range workingDays {
		for period := range periods {
			out = append(out, fmt.Sprintf("%v %v", day, period))
		}
	}

	return out

}

type Curriculum struct {
	Hours   int
	Level   string
	Subject string
}

func getCurriculum(all []Curriculum, level string, subject string) int {

	for _, rec := range all {
		if rec.Subject == subject && rec.Level == level {
			return rec.Hours
		}
	}

	return 0

}
*/
